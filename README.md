# Simplify your CI/CD workflow for lambda using GitHub Actions and Serverless framework

## What are we going to accomplish?

### The most common development and delivery workflow

1.	Developer creates a feature branch out of master for a new task.
2.	Develop on local machine with feature branch.
3.	Merge the feature branch into DEV branch to push the change to DEV environment. Developer validate the change.
4.	Merge the feature branch into QA branch to push the change to QA environment for QA team to validate and approve.
5.	Create pull request for master branch (ready for release).
6.	Merge pull request to master triggers the Stage/Pre-Prod build.
7.	QA team validate the change and perform regression test in Stage/Pre-Prod.
8.	Promote the release tag validated in Stage to Production.
9.	QA team validate the change and perform regression test in Production.
10.	Revert back to last working version in case of issue.


### and the value additions

1.	Automatically create release tag on code merge to master based on semver convention.
2.	Automatically create release notes and update changelog file based on the commit history.
3.	Send release note as email using AWS SNS.
4.	Enforce conventional commits using commitLint and husky commit-msg hook.
5.	Enforce code lint and run test before push using husky pre-commit and pre-push hooks.


## Prerequisites

You should be familiar with [Serverless framework](https://www.serverless.com/framework/docs/getting-started/) , YAML and some basics of CI/CD process.

## Local development

Run `yarn install` in project directory to install packages from `package.json` and run yarn run `sls:offline` to run the application in local using serverless offline.

## Configurations

### Secrets

You may need to set up an AWS user with IAM permission to run the build( like create/update CloudFormation stack, lambda, API gateway, S3 , SNS, IAM role) and generate ACCESS_KEY_ID and SECRET_ACCESS_KEY to use with GitHub actions.

Add the secret variables into GitHub repository > `settings` > `Secrets` to use with workflow files.

![alt text](https://github.com/loganH/serverless_githubaction_demo/blob/master/docs/secrets.png?raw=true)

### Workflow files

GitHub Actions Workflow defines on what events what actions needs to run on what orders. Jobs are high level tasks and steps are subtasks of jobs. Workflow files are kept under `.github/workflows`. We can kick off workflow for any GitHub events like push, pull, clone, create pull request, merge PR, comment on PR/commit, etc.

### Conventional commits

Conventional commits is enforced using [@commitlint/config-conventional](https://www.npmjs.com/package/@commitlint/config-conventional). We use [standard-version](https://www.npmjs.com/package/standard-version) to generate release tag and update changelog during our build process, which does versioning using semver and CHANGELOG generation powered by Conventional Commits.

### Resources

AWS resources can be provisioned through `serverless.yml` using [Serverless Framework](https://www.serverless.com/framework/docs/providers/aws/guide/resources/) or through separate CloudFormation template.

## Continuous Integration

CI workflow are added to `.github/workflow/ci.yml`. It does kicks offs on push to any branches except the primary branches (dev,qa,master).
`ci.yml` excludes the primary branches as CD workflow takes care of build, test and deploy on code push to primary branches.

CI workflow do checkout the branch on push, install packages from `package.json` and run the test, so that the developer can know the errors the update introduced during the early stages of development.

## Continuous Delivery

### Deploy non-production

On code push to non production branches `dev` and `qa` workflow files `cd-dev.yml` or `cd-qa.yml` kicks off to checkout latest code from respective branch, install packages, run test and deploy the lambda function to aws account added via secrets.

### Deploy Pre Production

On code push to `master` branch, Instruction in the workflow files `cd-stage.yml` kicks off to and does the following

1. Checkout master.
2. Install packages.
3. Run test.
4. Generate release notes to send as email via SNS and save it in temp file `npm run release -- --dry-run > releaseNotes.txt`.
5. Format the release notes using custom shell script `./changelog.sh`.
6. Update CHANGELOG and create release tag using [standard-version](https://www.npmjs.com/package/standard-version) `npm run release`.
7. Commit and push the CHANGELOG and release tag to GitHub master branch using the action [ad-m/github-push-action](https://github.com/ad-m/github-push-action).
8. Deploy lambda to one region. (Note: the step `Deploy lambda to us-east-1` can be duplicated to push the code to multiple region)
9. Install aws cli and push the release notes available in temp file to SNS topic.

### Deploy Production

The release version tag needs to be deployed to production should be updated in `metadata.json` file of `prod-deploy` branch.

On code push to `prod-deploy` branch the workflow files `cd-prod.yml` kicks off and does the following

1. Checkout `prod-deploy`.
2. Check the modified files using action [jitterbit/get-changed-files](https://github.com/jitterbit/get-changed-files) if the metadata.json is changes then procced further else skip other steps.
3. Read the tag version to deploy form `metadata.json`.
4. Checkout the release tag version to be deployed.
5. Install Node and packages in `package.json`.
6. Run test.
7. Deploy lambda to one region. (Note: the step `Deploy lambda to us-east-1` can be duplicated to push the code to multiple region)
