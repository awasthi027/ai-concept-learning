# ai-concept-learning
Creating a project to learn ai concepts like rules, instructions, skills and custom agents.


# Run code coverage agent from local machine 
firt you have install gitbuh copilot CLI in your machine

gh copilot -p "@run-unit-tests" --allow-all-tools

# Push changes without agent review 

git push --no-verify


# How to test code review agent 

//Create branch from commit
git checkout -b swiftCodeReview d866b3761a

//Cherry pickrevmiew commit
git cherry-pick e8247deaa4

//Git push
// Git push will invoke prehook agent 
git push --set-upstream origin swiftCodeReview

//Make change, create new file and add some change
//And push the change 
git push

//Review should fail 
git cherry-pick 79fb29bffe
//Fixed conflict and commit and push the changes
//This time review should pass

git cherry-pick --skip
git push


# How to run Code-coverage Agent 

//Create branch from this commit 
git checkout -b codeCoverageAgent beed2cc

Run the agent 
gh copilot -p "@run-unit-tests" --allow-all-tools

//make some change in UI

//Again run the agent 
gh copilot -p "@run-unit-tests" --allow-all-tools

//It will indentify the test which all i need to run to cover new code.
