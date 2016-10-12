#!/bin/sh
### BEGIN INIT INFO
# Provides:          devicetree-overlay-uio 
# Required-Start:    $local_fs
# Required-Stop:
# Should-Start:
# Default-Start:     S
# Default-Stop:      0 1 6
# Short-Description: Load devicetree overlay from /lib/firmware
# Description:       Loads a devicetree for loading firmware and
#                    enabling uio0 driver.
### END INIT INFO



start() {
        echo "********************************************************************"
        echo "Applying Holosynth Devicetree overlay"
        echo "********************************************************************"
        mkdir /config/device-tree/overlays/uio0
        cp /lib/firmware/socfpga/uioreg_uio.dtbo /config/device-tree/overlays/uio0/dtbo
}
stop() {
        echo "********************************************************************"
        echo "Removing Holosynth Devicetree overlay"
        echo "********************************************************************"
        rmdir /config/device-tree/overlays/uio0
}
restart() {
        stop
        start
}

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart|reload)
        restart
        ;;
  *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac

exit $?

