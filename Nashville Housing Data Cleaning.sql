
--Cleaning data in Nashville housing dataset

SELECT *
FROM dbo.nhp;



--Standardized date format. The sale date column had useless information that would not help in gathering insights. Such as time of day that the sale was made. For the purposes of this analysis it is not needed. 

SELECT saledate1 , CONVERT(Date , SaleDate)
FROM dbo.nhp

UPDATE dbo.nhp
SET SaleDate = CONVERT(Date , SaleDate);

ALTER TABLE dbo.nhp
ADD saledate1 Date; 

UPDATE dbo.nhp
SET saledate1 = CONVERT(Date , SaleDate);


-- Removing a duplicate column 'SaleDate'. I created new columns that converted the data to be more useful for analysis and do not have a need to have two of the same columns.

ALTER TABLE dbo.nhp
DROP COLUMN SaleDate;


-- Property address data. Here is where i joined the same table together so the proeprty addresses for duplicate values would be the same and not be a NULL value.

SELECT *
FROM dbo.nhp
WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

SELECT a.ParcelID , a.PropertyAddress , b.ParcelID , b.PropertyAddress , ISNULL(a.PropertyAddress , b.PropertyAddress)
FROM dbo.nhp AS a
JOIN dbo.nhp AS b 
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress , b.PropertyAddress)
FROM dbo.nhp AS a
JOIN dbo.nhp AS b 
ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Seperating address into individual columns (address , city , state) using the substring code. This allows the data to be more useful in gathering insights rather than having all that information in one column.
-- Substring can be more time consuming but I wanted to practice different ways of writing code and getting the same results.


SELECT PropertyAddress
FROM dbo.nhp

SELECT SUBSTRING(PropertyAddress , 1 , CHARINDEX(',' , PropertyAddress) -1) AS street_address
 , SUBSTRING(PropertyAddress , CHARINDEX(',' , PropertyAddress) + 1 , LEN(PropertyAddress)) AS city
FROM dbo.nhp

--Now I have to add these new columns into the dataset and update

ALTER TABLE dbo.nhp
ADD street_address NVARCHAR(255); 

UPDATE dbo.nhp
SET street_address = SUBSTRING(PropertyAddress , 1 , CHARINDEX(',' , PropertyAddress) -1)

ALTER TABLE dbo.nhp
ADD city NVARCHAR(255); 

UPDATE dbo.nhp
SET city = SUBSTRING(PropertyAddress , CHARINDEX(',' , PropertyAddress) + 1 , LEN(PropertyAddress))

-- I will check to make sure changes have been made and then remove 'PropertyAddress' column from dataset
-- Having multiple columns with the same data will take up space in the query and cause confusion later on.

SELECT *
FROM dbo.nhp;

ALTER TABLE dbo.nhp
DROP COLUMN PropertyAddress;

-- Seperating OwnerAddress data using PARSENAME (it will look for '.' not ','). Additionally it starts from the end of the code, so for this example specifically I had to start with 3 instead of 1

SELECT
	PARSENAME(REPLACE(OwnerAddress , ',' , '.') , 3)
	, PARSENAME(REPLACE(OwnerAddress , ',' , '.') , 2)
	,PARSENAME(REPLACE(OwnerAddress , ',' , '.') , 1)
FROM dbo.nhp


ALTER TABLE dbo.nhp
ADD ownerstreet_address NVARCHAR(255); 

UPDATE dbo.nhp
SET ownerstreet_address = PARSENAME(REPLACE(OwnerAddress , ',' , '.') , 3);

ALTER TABLE dbo.nhp
ADD ownercity_address NVARCHAR(255); 

UPDATE dbo.nhp
SET ownercity_address =  PARSENAME(REPLACE(OwnerAddress , ',' , '.') , 2);

ALTER TABLE dbo.nhp
ADD ownerstate_address NVARCHAR(255); 

UPDATE dbo.nhp
SET ownerstate_address = PARSENAME(REPLACE(OwnerAddress , ',' , '.') , 1);

--After confirming changes I will delete the 'OwnerAddress' column to get ride of duplicate data

ALTER TABLE dbo.nhp
DROP COLUMN OwnerAddress;

--In the 'SoldAsVacant' column I want to make sure all rows are defined as 'Yes' or 'No'. I will use a CASE to resove this issue.

SELECT DISTINCT(SoldAsVacant) , COUNT(SoldAsVacant)
FROM dbo.nhp
GROUP BY SoldAsVacant
ORDER BY 2; 

SELECT SoldAsVacant ,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM dbo.nhp

UPDATE dbo.nhp
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

-- I will be removing duplicates that will not be necessary in the dataset and whill help save space and improve performance of query

WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                        street_address,
                        SalePrice,
                        saledate1,
                        LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM dbo.nhp
)
-- Instead of '*' in the SELECT statement I can input 'DELETE' to get rid of all the duplicate rows
DELETE
From RowNumCTE
Where row_num > 1
--Order by street_address;


--I am going to remove data that I will not be using or looking at for this data

ALTER TABLE dbo.nhp
DROP COLUMN TaxDistrict; 

