kubectl create configmap nginx-proxy-conf --from-file nginx.conf -o yaml --dry-run > nginx.yaml
