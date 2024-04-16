#find the number of mines from file 2 within y Km distance of a village in File 1.
#  Repeat for every village in File 1

#imports
from math import radians, sin, cos, sqrt, asin
from tempfile import TemporaryDirectory
import pandas as pd
import os


#INPUTS

#file 1 is locations of interest
FILE1 = "clean_cooking/Python/data/DHS_Coordinates.csv"
#file 2 is x in proximity to locations of interest
FILE2 = "clean_cooking/Python/data/mines.csv"

#radius y that x may be to location of interest to be counted
Y = 50

#name of latitute and longitude across both files
LATITUDE = "LATNUM"
LONGITUDE = "LONGNUM"

#column name on df for final values to be written
WRITELOC1 = "n_mines"
WRITELOC2 = "avg_dist"
WRITELOC3 = "rms_dist"


#CONSTANTS (radius of Earth in Km) DO NOT CHANGE
RADIUS = 6372.8

#Path
path = '/Users/manavparikh/manav-workspace/clean_cooking/Python/data output'
output_file = os.path.join(path,'distance.csv')


df1 = pd.read_csv(FILE1)
df2 = pd.read_csv(FILE2)


def main():
    df1[WRITELOC1] = number()
    df1[WRITELOC2] = avg_dist()
    df1[WRITELOC3] = closest_mine()
    #write a zip file with output
    #compression_opts = dict(method='zip',archive_name='distance.csv') 
    df1.to_csv(output_file, index=False) #compression=compression_opts)
    return None


#calculate the distance between two points using haversine approximation
def havdistance(coord1, coord2) -> float:
#difference between lats and longs in radians
    deltalat = radians((coord2[0] - coord1[0]))
    deltalong = radians((coord2[1] - coord1[1]))
# each term within sqrt
    sin2lat = (sin(deltalat / 2.0)) ** 2
    coslat1 = cos(radians(coord1[0]))
    coslat2 = cos(radians(coord2[0]))
    sin2long = (sin(deltalong / 2.0)) ** 2
#calculate final sqrt
    sqrtterm = sqrt((sin2lat + (coslat1 * coslat2 * sin2long)))
#final distance
    dist = 2 * RADIUS * asin(sqrtterm)
    return dist

#calculate the number of x in file 2 within y radius
def number():
    num: int = 0
    mines: list = []
    coordinate1 = list(zip(df1[LATITUDE], df1[LONGITUDE]))
    coordinate2 = list(zip(df2[LATITUDE], df2[LONGITUDE]))
    for coord in coordinate1:
        for coord2 in coordinate2:
            dist = (havdistance(coord, coord2))
            if dist <= Y:
                num += 1
        mines.append(num)
        num = 0
    return (mines)

def avg_dist():
    mines: list = []
    coordinate1 = list(zip(df1[LATITUDE], df1[LONGITUDE]))
    coordinate2 = list(zip(df2[LATITUDE], df2[LONGITUDE]))
    for coord in coordinate1:
        disti: list = []
        for coord2 in coordinate2:
            dist = (havdistance(coord, coord2))
            disti.append(dist)
        avg = sum(disti)/len(disti)
        mines.append(avg)
    return (mines)

def rms_dist():
    mines: list = []
    coordinate1 = list(zip(df1[LATITUDE], df1[LONGITUDE]))
    coordinate2 = list(zip(df2[LATITUDE], df2[LONGITUDE]))
    for coord in coordinate1:
        disti: list = []
        for coord2 in coordinate2:
            dist = (havdistance(coord, coord2))
            disti.append(dist ** 2)
        avg = sum(disti)/len(disti)
        mines.append(sqrt(avg))
    return (mines)

def closest_mine():
    close: list = []
    finclose: list = []
    coordinate1 = list(zip(df1[LATITUDE], df1[LONGITUDE]))
    coordinate2 = list(zip(df2[LATITUDE], df2[LONGITUDE]))
    for coord in coordinate1:
        for coord2 in coordinate2:
            close.append((havdistance(coord, coord2)))
        finclose.append(min(close))
        close = []
    return (finclose)


if __name__ == '__main__':
    main()