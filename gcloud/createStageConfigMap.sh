kubectl delete configmap h-stage-config
kubectl create configmap h-stage-config \
  --from-file=app.ini=../conf/stage-app.ini \
  --from-file=websocket.ini=../conf/stage-websocket.ini \
  --from-file=alembic.ini=../conf/alembic.ini \
  --from-file=supervisord.conf=../conf/supervisord.conf \
  --from-file=nginx.conf
