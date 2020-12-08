from os import system as sys
import re
import statistics
import subprocess

def launch():
    sys("erlc network.erl")
    sys("erlc node_functions.erl")
    sys("erlc node.erl")
    sys("erlc main.erl")
    sys("erlc test.erl")

    sys("erl -noshell -eval 'test:test()' -run init stop > log.txt")

launch()

file = open("log.txt", 'r')
fileR = str(file.read())
source = fileR

listC = [ [0 for i in range(3) ] for i in range(180)]

p = re.compile('log:: .*')

nbr = 0
for log in re.findall(p, source):
    nbr +=1
    logs = log.split(" ")
    print(logs)


"""

for log in re.findall(p, source):
    for i in range(180):
            logs = log.split(" ")
            p2 = re.compile('{(.),')
            indegs = re.findall(p2, log)
            for indeg in indegs:
                if int(logs[1]) == i:
                    listC[i][int(indeg)] = listC[i][int(indeg)] + 1
print(listC)
mathFile = open("healer_deployment.data", 'w')
count = 0
for cycle in listC:
    #if (count%20 == 0):
        mean = statistics.mean(cycle)
        dev = statistics.stdev(cycle)
        mathFile.write(str(count) + " " + str(mean) + " " + str(dev) + "\n")
        count = count + 1
"""
