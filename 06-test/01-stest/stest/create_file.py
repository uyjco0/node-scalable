#!/usr/bin/python

__author__ = 'Jorge Couchet (jorge.couchet@gmail.com)'

import argparse
import csv
import random
import string

def generate_random_string(slength):
	'''It generates a random alphanumeric string with a fixed size given by "slength"'''
	return ''.join(random.choice(string.ascii_uppercase + string.ascii_lowercase + string.digits) for i in xrange(slength))

def generate_csv(fname, csv_lines, slength, csv_delimiter):
	'''It generates a new CSV file (replacing existing files with the same name) with name:"fname" and number of lines: "lines"'''

	print 'Starting to generate the file {} with {} lines ..'.format(fname, csv_lines)

	with open(fname, 'wb') as csvf:
		csvw = csv.writer(csvf, delimiter=csv_delimiter)
		for i in xrange(csv_lines):
			fname= generate_random_string(slength)
			csvw.writerow([fname + ' ' + generate_random_string(slength), fname + '@' + generate_random_string(slength)])

	print 'It has finished!!!'
		


if __name__ == '__main__':

	parser = argparse.ArgumentParser(description='It generates a new CSV file with random 2 column lines. The lines have the following format: "fname surname_D_fname@domain", where "_D_" is the provided delimiter (defaut is ",").')

	parser.add_argument('-f', '--fname', type=str, help='The name of the file to be generated', required=True)
	parser.add_argument('-l', '--lines', type=int, help='Number the lines in the file', required=True)
    	parser.add_argument('-s', '--slength', type=int, help='Number of characters to be used in the strings: "fname", "surname" and "domain". The default is: "16"', required=False, default=16)
	parser.add_argument('-d', '--delimiter', type=str, help='The delimiter for the CSV column lines. The default is: ","', required=False, default=',')


	args = parser.parse_args()

	if not args.fname:
		raise SystemExit('The file name cannot be empty')

	if args.lines < 1:
		raise SystemExit('The amount of lines must be equal or greater than 1, the current value is: %s' % args.lines)

	if args.slength < 1:
                raise SystemExit('The amount of characters to be used to build the random string must be equal or greater than 1, the current value is: %s' % args.slength)

    	generate_csv(args.fname, args.lines, args.slength, args.delimiter)
