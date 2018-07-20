#!/bin/bash 

SHARE_FOLDER=/opt/share
IMAGES_SERVER=$SHARE_FOLDER/images/server

removeImages() {
	sudo docker rmi $(docker images -q)
}

getImageField() {
  local imageId=$1
  local field=$2
  : ${imageId:? reuired}
  : ${field:? required}
  docker images --no-trunc|sed -n "/${imageId}/ s/ \+/ /gp"|cut -d" " -f $field
}

getImageName() {
  getImageField $1 1
}

getImageTag() {
  getImageField $1 2
}

saveImages() {
  local ids=$(docker images -q)
  local name safename tag

  for id in $ids; do
    name=$(getImageName $id)
    tag=$(getImageTag $id)
    file=$IMAGES_SERVER/$name.$tag.tar
    if [ ! -f $file ]; then
	    echo "save $file"
	    sudo mkdir -p $(dirname $file)
	    echo "Command: docker save -o $file $name:$tag"
	    (time  docker save -o $file $name:$tag) 2>&1|grep real
	else 
		echo "$file exist"
 	fi
  done
  chmod 755 $IMAGES_SERVER -R
}


loadImages() {
  local name safename noextension tag
  
  for image in $(find $IMAGES_SERVER -name \*.tar); do
    echo load  $image
    echo
    docker load -i $image
  done
}

saveImages
# loadImages
