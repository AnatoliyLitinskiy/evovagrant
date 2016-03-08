#!/bin/sh
# @usage bash cache-clear.sh
rm -rf app/cache/prod
echo ">          - - - php symfony cache:clear"
php symfony cache:clear
echo ">          - - - php symfony cache:clear -e prod"
php symfony cache:clear -e prod
echo ">          - - - php symfony assets:install --symlink"
php symfony assets:install --symlink
echo ">          - - - php symfony assetic:dump -e prod"
php symfony assetic:dump -e prod
