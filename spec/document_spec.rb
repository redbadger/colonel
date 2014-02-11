require 'spec_helper'

describe Document do
  describe "creation" do
    before do
      Rugged::Repository.stub(:new).and_return nil
    end

    it "should create a document" do
      expect(Document.new).to be_a Document
    end

    it "should have a random name" do
      document = Document.new
      expect(document.name).to match /^[0-9a-f]{16}$/
    end

    it "should have a name if specified" do
      document = Document.new 'test'
      expect(document.name).to eq 'test'
    end

    it "should have a content if specified" do
      document = Document.new('test', content: 'my test content')
      expect(document.content).to eq 'my test content'
    end
  end

  describe "git storage" do
    it "should create a repository with the document's name when asked for repo" do
      Rugged::Repository.should_receive(:init_at).with('storage/test', :bare)

      Document.new('test').repository
    end
  end

  describe "saving to storage" do
    let :repo do
      Object.new
    end

    let :index do
      Object.new
    end

    let :head do
      Struct.new(:target).new('head')
    end

    let :document do
      Document.new "test", content: "some content"
    end

    let :time do
      Time.now
    end

    before do
      document.stub(:repository).and_return(repo)
    end

    it "should create a commit on first save" do
      repo.should_receive(:write).with("some content", :blob).and_return('abcdef')

      Rugged::Index.should_receive(:new).and_return index
      index.should_receive(:add).with(path: "content", oid: 'abcdef', mode: 0100644)
      index.should_receive(:write_tree).with(repo).and_return 'foo'
      repo.should_receive(:empty?).and_return(true)

      options = {
        tree: 'foo',
        author: {email: 'git-cma@example.com', name: 'Git CMA', time: time},
        committer: {email: 'git-cma@example.com', name: 'Git CMA', time: time},
        message: 'save from Git CMA',
        parents: [],
        update_ref: 'HEAD'
      }

      Rugged::Commit.should_receive(:create).with(repo, options).and_return 'foo'

      expect(document.save(time)).to eq 'foo'
      expect(document.revision).to eq 'foo'
    end

    it "should add a commit on subsequent saves" do
      repo.should_receive(:write).with("some content", :blob).and_return('abcdef')

      Rugged::Index.should_receive(:new).and_return index
      index.should_receive(:add).with(path: "content", oid: 'abcdef', mode: 0100644)
      index.should_receive(:write_tree).with(repo).and_return 'foo'
      repo.should_receive(:empty?).and_return(false)
      repo.should_receive(:head).and_return(head)

      options = {
        tree: 'foo',
        author: {email: 'git-cma@example.com', name: 'Git CMA', time: time},
        committer: {email: 'git-cma@example.com', name: 'Git CMA', time: time},
        message: 'save from Git CMA',
        parents: ['head'],
        update_ref: 'HEAD'
      }
      Rugged::Commit.should_receive(:create).with(repo, options).and_return 'foo'

      expect(document.save(time)).to eq 'foo'
    end
  end

  describe "loading from storage" do
    let :repo do
      Object.new
    end

    let :commit do
      Object.new
    end

    let :tree do
      Object.new
    end

    let :file do
      Object.new
    end

    let :robj do
      Object.new
    end

    it "opening a document should open the repository and get HEAD" do
      Rugged::Repository.should_receive(:new).with("storage/test").and_return(repo)
      repo.should_receive(:head).and_return Struct.new(:target).new('abcdef')
      repo.should_receive(:lookup).with('abcdef').and_return(commit)
      commit.should_receive(:tree).and_return(tree)
      tree.should_receive(:first).and_return({oid: '12345', name: 'content'})
      repo.should_receive(:lookup).with('12345').and_return(file)
      file.should_receive(:read_raw).and_return(robj)
      robj.should_receive(:data).and_return('foo')

      doc = Document.open("test")
      expect(doc).to be_a(Document)
      expect(doc.repository).to eq(repo)
      expect(doc.revision).to eq('abcdef')
      expect(doc.content).to eq('foo')
    end

  end
end