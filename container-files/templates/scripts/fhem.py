#!/usr/bin/python

import sys, getopt
import simplejson as json
import urllib2

def main(argv):
   host = ''
   objectid = ''
   try:
      opts, args = getopt.getopt(argv,"hH:o:",["host=","oobjectid="])
   except getopt.GetoptError:
      print 'test.py -H <host> -o <objectid>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print 'test.py -H <host> -o <objectid>'
         sys.exit()
      elif opt in ("-H", "--host"):
         host = arg
      elif opt in ("-o", "--objectid"):
         objectid = arg
   #print 'Host file is "', host
   #print 'ObjectID file is "', objectid

   url = "http://" + host + "/fhem?XHR=1&cmd=jsonlist2+serialNr=" + objectid
   #print url

   data = urllib2.urlopen(url)
   j = json.load(data)

   #print type(j["Results"][0])
   #print j["Results"][0]["Attributes"]
   #print j["Results"][0]["Attributes"]["model"]

   if "model" in j["Results"][0]["Attributes"]:
   	model = j["Results"][0]["Attributes"]["model"]
   if "subType" in j["Results"][0]["Attributes"]:
	subType = j["Results"][0]["Attributes"]["subType"]

   #print model 
   #print subType

   info = {}

   ############################
   #print j["Results"][0]["Readings"]

   item = "batteryLevel"
   out_as = "BATTERY_STATE"
   if item in j["Results"][0]["Readings"]:
	info[out_as] = j["Results"][0]["Readings"][item]["Value"]

   item = "ValvePosition"
   out_as = "VALVE_STATE"
   if item in j["Results"][0]["Readings"]:
        info[out_as] = j["Results"][0]["Readings"][item]["Value"]

   item = "actuator"
   out_as = "VALVE_STATE"
   if item in j["Results"][0]["Readings"]:
        info[out_as] = j["Results"][0]["Readings"][item]["Value"]

   item = "desired-temp"
   out_as = "SET_TEMPERATURE"
   if item in j["Results"][0]["Readings"]:
        info[out_as] = j["Results"][0]["Readings"][item]["Value"]
   
   item = "measured-temp"
   out_as = "ACTUAL_TEMPERATURE"
   if item in j["Results"][0]["Readings"]:
        info[out_as] = j["Results"][0]["Readings"][item]["Value"]   

   item = "humidity"
   out_as = "HUMIDITY"
   if item in j["Results"][0]["Readings"]:
        info[out_as] = j["Results"][0]["Readings"][item]["Value"]

   item = "temperature"
   out_as = "ACTUAL_TEMPERATURE"
   if item in j["Results"][0]["Readings"]:
        info[out_as] = j["Results"][0]["Readings"][item]["Value"]

   item = "UR_TEMPERATURE_T1"
   out_as = "TEMPERATURE_SENSOR1"
   if item in j["Results"][0]["Readings"]:
        info[out_as] = j["Results"][0]["Readings"][item]["Value"]

   item = "UR_TEMPERATURE_T2"
   out_as = "TEMPERATURE_SENSOR2"
   if item in j["Results"][0]["Readings"]:
        info[out_as] = j["Results"][0]["Readings"][item]["Value"]

   item = "dewpoint"
   out_as = "DEWPOINT"
   if item in j["Results"][0]["Readings"]:
        info[out_as] = j["Results"][0]["Readings"][item]["Value"]

   item = "rssi"
   out_as = "RSSI_STATE"
   if "helper" in j["Results"][0]:
	if "rssi" in j["Results"][0]["helper"]:
		if "at_HMLAN0" in j["Results"][0]["helper"]["rssi"]:
			info[out_as] = j["Results"][0]["helper"]["rssi"]["at_HMLAN0"]["avg"]

   #print info

   ############################
#   elif type == "VARDP":
#
#        item = "VALVE"
#        data = urllib2.urlopen(url)
#        j = json.load(data)
#        info[item] = j["value"]


   #####################
   temp = ""
   for key in info:
	if info[key] == "null":
		info[key] = 0

        temp += key + ":" + "%.2f" % float(info[key]) + " "
        #temp += key + ":" + info[key] + " "
   print temp
   #####################



if __name__ == "__main__":
   main(sys.argv[1:])
