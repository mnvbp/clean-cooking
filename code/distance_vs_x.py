#take dataframe and count how many instances of anemia per village
import pandas as pd
import os

#Files to use
FILE1 = "clean_cooking/Python/data/finaldata.csv"
FILE2 = "clean_cooking/Python/data/distance.csv"

#File output
path = '/Users/manavparikh/manav-workspace/clean_cooking/Python/data output'
output_file = os.path.join(path,'distance_vs_pregterm.csv')

df1 = pd.read_csv(FILE1)
df2 = pd.read_csv(FILE2)

def main():
    key = list(df2["DHSID"])
    num: list = []
    for row in key:
        counter: int = 0
        temp = df1.loc[df1['DHSID'] == row, 'pregterm']
        for row2 in temp:
            if row2 == 1.0:
                counter += 1
        num.append(counter)
    df2["n_anemia"] = num
    #compression_opts = dict(method='zip',archive_name='distance_vs_pregterm.csv') 
    df2.to_csv(output_file, index=False) #compression=compression_opts)

    
if __name__ == '__main__':
    main()