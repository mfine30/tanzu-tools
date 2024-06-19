#!/bin/zsh
Help()
{
   echo "Basic utility to evaluate for a given Profile, which Cluster Groups provide its required capabilities."
   echo
   echo "Syntax: ./capability-checker [-p profile] [-g cluster_group] [-h]"
   echo
   echo "options:"
   echo "  p     Fully qualified Profile name."
   echo "  g     Fully qualified Cluster Group name."
   echo "  h     Print this Help."
   echo ""
   printf 'This is a utility designed to help you - a platform engineer - design your platform in the way you see fit. This tool lets
you validate that your Cluster Groups are configured to run the types of workloads that you intend them for. For example, make sure
your web-app Cluster Group provides all of the Capabilities that your web-app Profiles require. Or that your AI Cluster Group provides
all of the Capabilities that your AI Profiles require.\n'
}

profile=""
cluster_group=""

CYAN='\033[0;36m'
NC='\033[0m'

if [ -z "$1" ]; then
  Help
  exit 1;
fi

while getopts ":hp:g:" option; do
   case $option in
      h)
       Help
       exit;;
     p)
       profile=${OPTARG};;
     g)
       cluster_group=${OPTARG};;
     :)
        echo -e "option requires an argument.\nUsage: $(basename $0) [-p profile -g cluster group]"
        exit 1;;
     ?) # Invalid option
       echo "Error: Invalid option"
       echo -e "Usage: $(basename $0) [-p profile -g cluster group]"
       exit;;
    esac
done

if [ -z "${profile}" ]; then
  echo "Error: profile is required."
  echo -e "Usage: $(basename $0) [-p profile -g cluster group]"
  exit 1
fi

if [ -z "${cluster_group}" ]; then
  echo "Error: cluster group is required."
  echo -e "Usage: $(basename $0) [-p profile -g cluster group]"
  exit 1
fi

echo "Using context:"
tanzu context current | grep -E 'Name|Organization|Project'

tanzu profile get $profile -oyaml > /dev/null
if [ $? -ne 0 ]; then
  echo -e "\nError: Profile ${CYAN}$profile${NC} does not exist"
  exit
fi

tanzu ops clustergroup get $cluster_group &> /dev/null
if [ $? -ne 0 ]; then
  echo -e "\nError: Cluster Group ${CYAN}$cluster_group${NC} does not exist"
  exit
fi


#fetch required capabilities in profile
required=($(tanzu profile get $profile -oyaml | yq  '.status.requiredCapabilities[].name'))

echo -e "\nProfile ${CYAN}$profile${NC} requires the following capabilities"
for cap in "${required[@]}"; do
  echo "  - $cap"
done

KUBECONFIG=/Users/$USER/.config/tanzu/kube/config

# fetch all capabilities provided in cluster group
provided=($(KUBECONFIG=$KUBECONFIG kubectl get kubernetesclusters -o jsonpath='{.items[*].status.capabilities[*].name}'))

# simplify to only uniquely provided capabilities
declare -A uniq
for p in "${provided[@]}"; do 
  uniq[$p]="true"
done

# identify and list missing capabilities
missing_caps=()
for value in "${required[@]}"; do
  if [[ $uniq[$value] != "true" ]]; then
    missing_caps+=($value)
  fi
done

if [ "${#missing_caps}" = 0 ]; then
  echo -e "\nCluster Group ${CYAN}$cluster_group${NC} provides all required capabilities for Profile ${CYAN}$profile${NC}."
  exit
fi

echo -e "\nCluster Group ${CYAN}$cluster_group${NC} is missing the following capabilities:"
for cap in "${missing_caps[@]}"; do
  echo "  - $cap"
done
