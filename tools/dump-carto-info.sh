#!/bin/sh

#  CARTO 3 Self hosted dump kubernetes info
#
# Usage:
#   dump_carto_info.sh --n <namespace> --release <helm_release>
#

bad_arguments() {
	echo "Missing or bad arguments"
	print_help
	exit 1
}

print_help() {
	cat <<-EOF
		usage: bash dump-carto-info.sh [-h] --namespace NAMESPACE --release HELM_RELEASE

		mandatory arguments:
			--namespace NAMESPACE                                                    e.g. carto
			--release   HELM_RELEASE                                                 e.g. carto

		optional arguments:
			-h, --help                                                               show this help message and exit
	EOF
}

ARGS=("$@")

for index in "${!ARGS[@]}"; do
	case "${ARGS[index]}" in
	"--namespace")
		NAMESPACE="${ARGS[index + 1]}"
		;;
	"--release")
		HELM_RELEASE="${ARGS[index + 1]}"
		;;
	"--*")
		bad_arguments
		;;
	esac
done

# Check all mandatories args are passed by
if [ -z "${NAMESPACE}" ] ||
	[ -z "${HELM_RELEASE}" ]; then
	bad_arguments
fi

DUMP_FOLDER="${HELM_RELEASE}-${NAMESPACE}_$(date "+%Y.%m.%d-%H.%M.%S")"
mkdir ${DUMP_FOLDER}

echo "Downloading helm release info..."
helm list -n "${NAMESPACE}" > ${DUMP_FOLDER}/helm-release.out

echo "Downloading pods..."
kubectl get pods -n "${NAMESPACE}" -o wide -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/pods.out

echo "Downloading services..."
kubectl get svc -n "${NAMESPACE}" -o wide -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/services.out

echo "Downloading endpoints..."
kubectl get endpoints -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/endpoints.out

echo "Downloading deployments..."
kubectl get deployments -n "${NAMESPACE}" -o wide -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/deployments.out

echo "Downloading ingress..."
INGRESS_NAME=$(kubectl get ingress -n "${NAMESPACE}" -o jsonpath='{.items[0].metadata.name}' -l app.kubernetes.io/instance="${HELM_RELEASE}")
kubectl describe ingress ${INGRESS_NAME} -n "${NAMESPACE}" > ${DUMP_FOLDER}/ingress.out

echo "Downloading BackendConfigs..."
BACKENDCONFIG_NAME=$(kubectl get backendconfigs -n "${NAMESPACE}" -o jsonpath='{.items[0].metadata.name}' -l app.kubernetes.io/instance="${HELM_RELEASE}")
kubectl describe backendconfigs ${BACKENDCONFIG_NAME} -n "${NAMESPACE}" > ${DUMP_FOLDER}/backendconfigs.out

echo "Downloading FrontEndConfig..."
FRONTENDCONFIG_NAME=$(kubectl get frontendconfigs -n "${NAMESPACE}" -o jsonpath='{.items[0].metadata.name}' -l app.kubernetes.io/instance="${HELM_RELEASE}")
kubectl describe frontendconfigs ${FRONTENDCONFIG_NAME} -n "${NAMESPACE}" > ${DUMP_FOLDER}/frontendconfigs.out

echo "Downloading events..."
kubectl get event -n "${NAMESPACE}" > ${DUMP_FOLDER}/events.out

echo "Downloading secrets info without passwords..."
kubectl describe secrets -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/secrets.out
