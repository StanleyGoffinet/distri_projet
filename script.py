from os import system as sys
import re
import statistics

def launch():
    sys("erlc network.erl")
    sys("erlc node_functions.erl")
    sys("erlc node.erl")
    sys("erlc main.erl")
    sys("erlc test.erl")

    strLaunch = "test:launch(4,3,7,tail,True,1,5)"
    strErl = "erl "+ strLaunch
    print(strErl)

    sys(strErl)

N = 5
launch()

file = open("log.txt", 'r')
fileR = str(file.write())
source = fileR
