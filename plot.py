#!/usr/bin/python3

#
# plot.py: generate SVG of Birthday Problem data from given input data.
#

import csv
import sys
# import numpy as np
import matplotlib.pyplot as plt

def read_csv(path):
  with open(sys.argv[1], newline = '') as fh:
    return list([row for row in csv.DictReader(fh)])

# check arguments
if len(sys.argv) < 3:
  print("Usage: {} input.csv output.svg".format(sys.argv[0]))
  exit(-1)

# read csv
rows = read_csv(sys.argv[1])
lo_rows = [row for row in rows if (float(row['Probability']) <= 0.5)]
hi_rows = [row for row in rows if (float(row['Probability']) > 0.5)]

# sort by range
# rows.sort(key = lambda row: int(row['range']))

# plot lower values
plt.bar(
  [int(row['Number of People']) for row in lo_rows],
  [(100.0 * float(row['Probability'])) for row in lo_rows], 
  # align = 'center',
  alpha = 0.5,
)

# plot upper values
plt.bar(
  [int(row['Number of People']) for row in hi_rows],
  [(100.0 * float(row['Probability'])) for row in hi_rows], 
  # align = 'center',
  alpha = 0.5,
  color = 'red'
)

# add label and title
plt.yticks(fontsize = 5)
plt.xlabel('Number of People')
plt.ylabel('Probability of Shared Birthday (%)')
plt.title('Number of People vs. Probability of Shared Birthday', fontsize = 9)
plt.tight_layout()

# save image
plt.savefig(sys.argv[2])
