# AWSBootClient
rake task for boot/stop instances on AWS and create config file

### Setup
```
export AWS_REGION=ap-northeast-1
export GPU_AWS_ACCESS_ID=xxxxx
export GPU_AWS_ACCESS_SECRET_=xxxx
bundle install
```

### command
```
bundle exec rake setup_ssh #boot stopped instances and setup config
bundle exec rake stop_instance #stop instances
```
