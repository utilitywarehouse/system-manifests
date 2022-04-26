Uses kustomize base from https://github.com/kubernetes-sigs/aws-ebs-csi-driver
to deploy the CSI driver.

Additionally, it patches the controller deployment to run on masters and utilise
the respective EC2 instance role, instead of using AWS credentials.
We also patch the daemonset ClusterRole to allow scheduling on our nodes.
