#-*- coding:utf-8 -*-

import os
import csv
import pprint
import predict as pd

people_ = os.listdir(os.getcwd() + '/csvs')
people_output = []

people = [ p for p in people_ if 'csv' in p ]

print(people)
exceptions = []

for p in people :
	list = []
	f = open(os.getcwd() + '/csvs/' + p, "r")
	try :
		for line in csv.reader(f) :
			list.append(line)
	except :
		exceptions.append(p)
	people_output.append(list)
  #people_output.append( [line[1] for line in rdr] )
	f.close()

print(exceptions)

for out in people_output :
	for o in out :
		o.append(pd.predict_pos_neg(o[1]))

for i in range(len(people)) :
	f = open(os.getcwd() + '/csvs/' + 'ano' + people[i], "w")
	wr = csv.writer(f)
	for o in people_output[i] :
		wr.writerow(o)
	f.close()


