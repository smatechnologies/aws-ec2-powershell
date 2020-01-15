# AWS EC2 Powershell Examples
The files in this repository are to assist with managing AWS EC2 instances.  Using the examples in these scripts, you will be able to start/stop/remove/create EC2 Instances, create an image, and add/remove IP addresses from an AWS security group.

# Prerequisites
* PowerShell v5.1+
* <a href url ="https://aws.amazon.com/powershell">AWS Powershell SDK</a>

# Instructions
Prior to running any scripts on AWS you will need to setup your authentication profile in Powershell.  Instructions for that can be found <a href url="https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-started.html">here</a>.

The module file in this repository contains numerous functions to make writing other scripts easier. The first step you will need to do when creating your own script will be to import the module file as well as the AWSPowershell module (installed with the SDK).

Example:
```
Import-Module AWSPowershell -Force
Import-Module -Name "C:\AWS_EC2_module.psm1" -Force
```

# Disclaimer
No Support and No Warranty are provided by SMA Technologies for this project and related material. The use of this project's files is on your own risk.

SMA Technologies assumes no liability for damage caused by the usage of any of the files offered here via this Github repository.

# License
Copyright 2020 SMA Technologies

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

# Contributing
We love contributions, please read our [Contribution Guide](CONTRIBUTING.md) to get started!

# Code of Conduct
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code-of-conduct.md)
SMA Technologies has adopted the [Contributor Covenant](CODE_OF_CONDUCT.md) as its Code of Conduct, and we expect project participants to adhere to it. Please read the [full text](CODE_OF_CONDUCT.md) so that you can understand what actions will and will not be tolerated.
