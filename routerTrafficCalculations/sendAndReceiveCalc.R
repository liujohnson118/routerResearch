rm(list=ls())
dataReceived<-read.table('/Users/geyi/documents/dataReceived_987by_10i_30fps.txt',sep=',')
dataSent<-read.table('/Users/geyi/documents/dataSent_987by_10i_30fps.txt',sep=',')

##Loop through data received
receivedTime<-vector()
idReceived<-vector()

for(i in 1:ncol(dataReceived)){
  tempDataReceived<-strsplit(toString(dataReceived[1,i])," ")[[1]]
  receivedTime<-c(receivedTime,as.numeric(tempDataReceived[2]))
  idReceived<-c(idReceived,as.numeric(tempDataReceived[4]))
}


##Loop through data sent
sentTime<-vector()
idSent<-vector()
for(j in 2:nrow(dataSent)){
  tempDataSent<-strsplit(toString(dataSent[j,1])," ")[[1]]
  sentTime<-c(sentTime,as.numeric(tempDataSent[2]))
  idSent<-c(idSent,as.numeric(tempDataSent[4]))
}

allReceived<-data.frame(timeOfReceive=receivedTime,idOfReceive=idReceived)
allSent<-data.frame(timeOfSend=sentTime,idOfSent=idSent)

allReceived<-allReceived[complete.cases(allReceived),]
allSent<-allSent[complete.cases(allSent),]
timeInfo<-merge(allReceived,allSent,by.x='idOfReceive',by.y='idOfSent')
timeInfo$delay=timeInfo$timeOfReceive-timeInfo$timeOfSend
plot(timeInfo$idOfReceive,timeInfo$delay,main="2m 987byts 10-ipads 30fps",xlab="packetID",ylab="delay (s)")
