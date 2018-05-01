kubectl delete configmap h-config
kubectl create configmap h-config \
  --from-file=app.ini=../conf/app.ini \
  --from-file=websocket.ini=../conf/websocket.ini \
  --from-file=alembic.ini=../conf/alembic.ini \
  --from-file=supervisord.conf=../conf/supervisord.conf \
  --from-file=nginx.conf
