# msk admin client

It's a jump pod setup for doing admin tasks related to MSK

Has 2 containers: 
1. kafka-client: used to run kafka cli commands against MSK as admin. Used when scaling up the cluster for reassigning partitions. Using it is described [here](https://github.com/utilitywarehouse/documentation/blob/master/infra/operational/msk-ops.md#how-to-run-kafka-client-commands)
2. tf-kafka-config: used to apply & debug the MSK topics configuration from [kafka-cluster-config](https://github.com/utilitywarehouse/kafka-cluster-config). Useful when we have to delete topics from prod. It's the only way we can do this. See [here](https://github.com/utilitywarehouse/documentation/blob/master/infra/operational/msk-ops.md#terraformappliererrors)
