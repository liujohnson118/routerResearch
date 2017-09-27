rm(list=ls())
dataReceived<-read.table('/Users/geyi/documents/dataReceived.txt',sep=',')
dataSent<-read.table('/Users/geyi/documents/dataSent.txt',sep=',')

##Loop through data received
receivedTime<-vector()
receiveInstantSpeed<-vector()

for(i in 1:ncol(dataReceived)){
  tempDataReceived<-strsplit(toString(dataReceived[1,i])," ")[[1]]
  receivedTime<-c(receivedTime,as.numeric(tempDataReceived[2]))
  receiveInstantSpeed<-c(receiveInstantSpeed,as.numeric(tempDataReceived[4]))
}


##Loop through data sent
sentTime<-vector()
sentInstantSpeed<-vector()
for(j in 2:nrow(dataSent)){
  tempDataSent<-strsplit(toString(dataSent[j,1])," ")[[1]]
  sentTime<-c(sentTime,as.numeric(tempDataSent[2]))
  sentInstantSpeed<-c(sentInstantSpeed,as.numeric(tempDataSent[3]))
}
