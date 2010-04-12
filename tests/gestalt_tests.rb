require File.expand_path(File.dirname(__FILE__) + '/tests_helper')

Shindo.tests("Gestalt") do
  test("fails") do
    "hey buddy, you should probably rename this file and start specing for real"
    false
  end
end
