Given /^that game has that profile$/ do
  @game.profile_ids << @profile.id
  @game.save!
end

Then /^the last game should have (\d+) profiles$/ do |arg1|
  Game.last.profile_ids.size.should == arg1.to_i
end


Given /^the last game has the strategy "([^"]*)"$/ do |arg1|
  game = Game.last
  game.add_strategy("All", arg1)
  game.save!
end

When /^I delete the strategy "([^"]*)" from that game$/ do |arg1|
  Game.last.delete_strategy_by_name("All", arg1)
end

Then /^that game should have a role named "([^"]*)" with the strategy array "([^"]*)"$/ do |arg1, arg2|
  r = Game.last.roles.where(name: arg1).first
  r.should_not == nil
  r.strategy_names.should == eval(arg2)
end
Then /^the first game should have (\d+) profiles$/ do |arg1|
  Game.first.profile_ids.size.should == arg1.to_i
end


Then /^that game should have the role "([^"]*)" with strategies "([^"]*)" and "([^"]*)"$/ do |arg1, arg2, arg3|
  Game.last.roles.first.name.should == arg1
  Game.last.roles.first.strategy_names.should == [arg2, arg3]
end

Then /^that game should have (\d+) profiles$/ do |arg1|
  Game.last.profile_ids.count.should == arg1.to_i
end