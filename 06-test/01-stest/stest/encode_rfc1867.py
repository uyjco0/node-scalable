#!/usr/bin/python

__author__ = 'Jorge Couchet (jorge.couchet@gmail.com)'

import argparse
import csv


def encode_file(fin, fout, delimiter):
	'''It encodes a given CSV file in a base64 string and save the result following the RFC 1867'''

	with open(fin, 'rb') as reqf:

		reqr = csv.reader(reqf, delimiter=delimiter)

		with open(fout, 'wb') as resf:

			# The boundary, 1234567890 should be a value guaranteed not to appear in the fin 's content
    			resf.write('-----------------------------126474506989943511588532701' + '\r\n')
			resf.write('Content-Disposition: form-data; name="filefield"; filename="' + fin + '"' + '\r\n')
			resf.write('Content-Type: text/csv' + '\r\n')
			resf.write('\r\n')
			for row in reqr:
				resf.write(delimiter.join(row) + '\r\n')
			resf.write('\r\n')
			resf.write('-----------------------------126474506989943511588532701--')
		
	print 'The file ' + fin + ' has been encoded in the file ' + fout
		


if __name__ == '__main__':

	parser = argparse.ArgumentParser(description='It receives a CSV file and generates an equivalent encoded file that ApacheBench (ab) can use in a form based file upload ')

	parser.add_argument('-i', '--fin', type=str, help='The name of the file to be encoded', required=True)
	parser.add_argument('-o', '--fout', type=str, help='The name of the equivalent file to be generated. The default is: "text.txt"', required=False, default='test.txt')
	parser.add_argument('-d', '--delimiter', type=str, help='The delimiter for the CSV column lines. The default is: ","', required=False, default=',')

	args = parser.parse_args()

	if not args.fin:
		raise SystemExit('The name of the file to be encoded cannot be empty')

    	encode_file(args.fin, args.fout, args.delimiter)
