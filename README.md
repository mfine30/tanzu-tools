# tanzu-tools

Basic utility to evaluate if a Cluster Groups provides all Capabilities that a Profile requires.

This utility is designed to help you - a platform engineer - design your platform in the way you see fit. This tool lets
you validate that your Cluster Groups are configured to run the types of workloads that you intend them for. For example, make sure
your web-app Cluster Group provides all of the Capabilities that your web-app Profiles require. Or that your AI Cluster Group provides
all of the Capabilities that your AI Profiles require.

```
Syntax: ./capability-checker [-p profile] [-g cluster_group] [-h]

options:
  p     Fully qualified Profile name.
  g     Fully qualified Cluster Group name.
  h     Print this Help.
```

### Notes
* Requires `tanzu cli`, `kubectl`, `zsh`, and `yq`
