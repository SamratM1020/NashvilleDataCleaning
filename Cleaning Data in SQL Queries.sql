SELECT * FROM NashvilleHousing

/* Standardise Date Format */

SELECT SaleDate
FROM NashvilleHousing
-- SaleDate is in datetime format, want to convert it to just YYYY-MM-DD, which is the 'date' format
-- CONVERT(data_type, expression), where data_type is what we want to convert it to and expression is column name

SELECT SaleDate, CONVERT(date, SaleDate)
FROM NashvilleHousing

-- changing the data type of SaleDate
UPDATE NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate) 

-- see if this works:
SELECT SaleDate
FROM NashvilleHousing
-- ^ this does not work because UPDATE function does not change data types
-- we will need to use the ALTER COLUMN function to change the data type of a column [SaleDate]

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate date;

--see if this works:
SELECT SaleDate
FROM NashvilleHousing
-- ^ now it works!

-- alternative method could be to add a new column and updating the column by setting it to be equal to convert function


----------------------------------------------------------------------------------------------------------------------------


/* Populate Property Address Data */

-- there are NULL values so we are going to look at that

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL
-- the address isn't going to change. The owner's addres might change but not the address of the property itself won't
-- PropertyAddress could be populated if we had a reference point to base it off of.

-- look at everything again:
SELECT *
FROM NashvilleHousing
ORDER BY ParcelID
-- ^ row 44 and 45 have the same ParcelID, and also have the exact same PropertyAddress
-- this Parcel ID is going to be the same as the property address
-- so if one of the same two ParcelIDs has an address and the other doesn't (NULL), we can populate it with that address!

-- going to need to perform a SELF JOIN on the table
SELECT *
FROM NashvilleHousing AS a
INNER JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] -- need to find a way to distinguish. SaleDate could be the same but UniqueID is unique

-- ^ we have joined the same exact table to itself where the ParcelID is the same but it's not the same row as there's a UniqueID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousing AS a
INNER JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
-- we can see that parcel ID and property address from a tends to match those in b
-- there are null values so we filter by them next:

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousing AS a
INNER JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL              -- note: can also do "b.PropertyAddress IS NULL" too

-- ^ we have an address for all of these null values but we haven't populated it yet
-- so what we need to do is use the ISNULL function on the SELECT statement: ISNULL(expression, value). Value to return if expression is null

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
INNER JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- now we need to UPDATE the records in the table where the null values in a.PropertyAddress are replaced by those in b.PropertyAddress
-- when doing joins in an update statement, need to specify which table it is through its ALIAS (in this case, a)

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
INNER JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL
-- then check the query before the above and you'll see that there are no nulls and therefore the UPDATE statement was correct!

-- side note: you can even use the ISNULL statement to populate the null values with a string if we wished to
-- (go back to my Barcelona 2014/15 table and use ISNULL to replace nulls with zeros)


----------------------------------------------------------------------------------------------------------------------


/* Breaking out address into individual columns, i.e. Address, City, State */

SELECT PropertyAddress
FROM NashvilleHousing
-- ^ there are no other commas anywhere except from in between address and city as a separator/delimiter 
-- delimiter is something that separates different columns or different values. Here, the delimiter is a comma

-- Going to be using the SUBSTRING and character index CHARINDEX functions

/*
SUBSTRING(expression, start_position, length). Where expression is aka string, start = starting position (first string is 1),
and length = number of characters to extract. 
				Returns a specific number of letters/numbers aka substrings

-- CHARINDEX(substring, expression, start). Where substring = the substring to be searched for (i.e. comma), epxression aka string
and start = starting location [optional].
				Returns the number in which the position of a substring is at. Default location is 1.
*/

SELECT 
	PropertyAddress, 
	CHARINDEX(',', PropertyAddress) AS CommaPosition
FROM NashvilleHousing
-- ^ returns the number, the position where the comma is, which varies 

-- now use this CHARINDEX() created onto the SUBSTRING function, this will be the "length" argument of the SUBSTRING function

SELECT 
	PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address
FROM NashvilleHousing
-- ^ in the Address column, the comma still shows, which we do not want to see
-- therefore we need to put a -1 after the CHARINDEX syntax to remove it, i.e. CommaPosition -1

SELECT 
	PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
FROM NashvilleHousing
-- now the comma is gone. Going to the comma and then going back 1 behind the comma


/* Next, we're getting the State */

--SUBSTRING(expression, start_position int, length int)
-- Where we want to start is after the blank space, which is after the comma i.e. CommaPosition +2
-- need to specify where it needs to finish. Everything is going to be different as addresses have a different length
-- but the way to work around this is by using the LEN(expression) function on length argument. Where the expression = PropertyAddress
SELECT
	PropertyAddress,
	LEN(PropertyAddress),
FROM NashvilleHousing

-- and as mentioned earlier , the starting position will be CommaPosition +2, aka the CHARINDEX() function:

SELECT
	PropertyAddress,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress)) AS City
FROM NashvilleHousing


-- now putting the two next to each other (without PropertyAddress):

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress)) AS City
FROM NashvilleHousing


-- we can't separate two values from one column without creating two other columns

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)
-- ^ address column added

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress))
-- ^ city column added

-- check if two new columns are at the end
SELECT *
FROM NashvilleHousing
-- and they are!

-------------------------------------------------------------------------------------------------------------------

/* Now going to look at the Owner Address */

SELECT OwnerAddress
FROM NashvilleHousing

-- instead of using SUBSTRING and CHARINDEX again, going to do something simpler: we will use PARSENAME()
-- which is very useful for delimited stuff. PARSENAME usually recognises full stops so we can replace commas with full stops

-- let's do this first
SELECT
	PARSENAME(OwnerAddress, 1)
FROM NashvilleHousing
-- ^ nothing changes because as said earlier, PARSENAME is only useful with periods. So let's REPLACE the commas with periods
-- REPLACE(OwnerAddress, ', ', '.') to replace OwnerAddress

SELECT
	PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 1)
FROM NashvilleHousing
-- ^ it's taking the State abbreviation

-- one thing about PARSENAME is that it does things backwards, i.e. :
SELECT
	PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 1),
	PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 3)
FROM NashvilleHousing

-- so all we need to do is just go from 3 to 1:
SELECT
	PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 3) AS OwnerSplitAddress,
	PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 2) AS OwnerSplitCity,
	PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 1) AS OwnerSplitState
FROM NashvilleHousing

-- and now we just need to add those columns to the table and add the values

ALTER TABLE NashvilleHousing
ADD 
	OwnerSplitAddress nvarchar(255),
	OwnerSplitCity nvarchar(255),
	OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET
	OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 1)

-- after that, use the command SELECT * FROM NashvilleHousing to check if they're there, and they are!


-------------------------------------------------------------------------------------------------------------------

/* Change Y and N to Yes and No in SoldAsVacant field */

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- will be using a CASE statement for this

SELECT SoldAsVacant,
	(CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END)
FROM NashvilleHousing
--WHERE SoldAsVacant IN ('Y', 'N')

-- now that we know how it works, we use the UPDATE function to make SoldAsVacant column to be equal to the CASE statement column

UPDATE NashvilleHousing
SET 
	SoldAsVacant = (CASE
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
					END)

-- now check SELECT DISTINCT SoldAsVacant FROM NashvilleHousing, and it works.


----------------------------------------------------------------------------------------------------------------------


/* Removing duplicates */

-- going to do a CTE and do some windows functions (partition by etc.) to find where there are duplicate values 

/*
We want to parition our data. When doing removing duplicates, we're going to have duplicate rows and we need to find a way
to be able to identify these rows. Can use things such as rank, dense_rank row_number etc.

Here, we're going to use the ROW_NUMBER() function because it is the simplest one for what we need to do here.

Going to select everything and then add our row number, then need to write our partition. Going to parition (group) this data.

Need to know what we're partitioning on. Need to do it on things that should be unique to each row.
We know that UniqueID is definitely unique so don't need to partition it on that.
However, things such as ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference are all the exact same in two different rows,
then we would consider that as a duplicate and should look to remove it.

And then after partitioning, order it by the unique ID.

*/


SELECT *,
	(ROW_NUMBER() OVER(
						PARTITION BY ParcelID,
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
						ORDER BY UniqueID)) AS row_num
FROM NashvilleHousing
ORDER BY ParcelID

-- need to partition it on things that should be unique to each row


-- Performing a CTE to identify the duplicates

WITH RowNumCTE AS
(SELECT *,
	ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
FROM NashvilleHousing)

SELECT *
FROM RowNumCTE
WHERE row_num > 1 -- then filter it by any ParcelID and check if all the values outside of UniqueID are the same
ORDER BY ParcelID
-- (note: can't have an ORDER BY clause inside the CTE)


-- now need to delete these duplicates, done by replacing 'SELECT *' with DELETE:

WITH RowNumCTE AS
(SELECT *,
	ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
FROM NashvilleHousing)

DELETE
FROM RowNumCTE
WHERE row_num > 1
-- get rid of the ORDER BY clause here (returns syntax error)

-- When executing the query before the one above, we can see that it works! There are no duplicate values now.



-------------------------------------------------------------------------------------------------------------------


/* Delete unused columns */ 

-- best practice is to not to do this to your raw data that comes into your database
-- talk to someone before you delete any columns 

-- going to get rid of PropertyAddress and OwnerAddress (since we have them split now), and TaxDistrict

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict

-- check if it works:
SELECT * 
FROM NashvilleHousing

