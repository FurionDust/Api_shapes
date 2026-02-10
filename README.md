# grupal_cloud


#pruebas de crud

# Create 
curl -X POST http://shape-app-alb-479140046.us-east-1.elb.amazonaws.com:6767/shapes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Circle",
    "color": "Red",
    "side": 2
  }'

# Read todas
curl -X GET http://shape-app-alb-479140046.us-east-1.elb.amazonaws.com:6767/shapes

#rEAD
curl -X GET http://localhost:6767/shapes/2

#update
curl -X PUT http://shape-app-alb-479140046.us-east-1.elb.amazonaws.com:6767/shapes/2 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Circle",
    "color": "Green",
    "sides": 4

  }'

# Delete s
curl -X DELETE http://shape-app-alb-479140046.us-east-1.elb.amazonaws.com:6767/shapes/1



#Proyecto grupal 
# https://github.com/FurionDust/Api_shapes/releases/download/jar/api-shapes.jar
