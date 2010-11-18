require 'spec_helper'

describe "Sequences" do
  it "should contain a list of tasks to be called" do
    @seq = Sequence.new :tasks => [:task1, :task2]
    @seq.__task_names.should == [:task1, :task2]
  end
end
