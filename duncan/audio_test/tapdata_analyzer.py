import csv

with open("taps.csv","rU") as f:
	reader = csv.reader(f)
	count = 0
	for row in reader:
		if count == 0: sds = [float(num) for num in row]
		if count == 1: 
			avgs = [float(num) for num in row]
			break
		count += 1

	ranges = []
	for i in xrange(len(avgs)):
		ranges.append([avgs[i]-sds[i],avgs[i]+sds[i]])
	print ranges