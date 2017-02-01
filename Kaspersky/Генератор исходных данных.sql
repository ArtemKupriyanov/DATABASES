

IF OBJECT_ID('[dbo].[Subscribers]', 'U') IS NOT NULL 
  DROP TABLE [dbo].[Subscribers]; 
  
IF OBJECT_ID('[dbo].[Products]', 'U') IS NOT NULL 
  DROP TABLE [dbo].[Products];

IF OBJECT_ID('[dbo].[History]', 'U') IS NOT NULL 
  DROP TABLE [dbo].[History]; 
  
CREATE TABLE [dbo].[Subscribers](
	[SubscriberId] [int] NOT NULL,
	[ProviderName] [varchar](50) NOT NULL,
	[SubscriberName] [varchar](50) NOT NULL,
	[SubscriptionStartDate] [datetime] NOT NULL,
	[SubscriptionEndDate] [datetime] NULL,
 CONSTRAINT [PK_Subscribers] PRIMARY KEY CLUSTERED 
(
	[SubscriberId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[Products](
	[ProductId] [int] IDENTITY(1,1) NOT NULL,
	[ProductCode] [varchar](max) NOT NULL,
 CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED 
(
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

CREATE TABLE [dbo].[History](
	[HistoryId] [int] IDENTITY(1,1) NOT NULL,
	[SubscriberId] [int] NULL,
	[ProductId] [int] NULL,
	[ChangeDate] [datetime] NULL,
 CONSTRAINT [PK_History] PRIMARY KEY CLUSTERED 
(
	[HistoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
BEGIN TRANSACTION;
BEGIN TRY

DECLARE @subscribersCount INT = 550
DECLARE @counter INT = 0

WHILE @counter <= @subscribersCount
BEGIN

DECLARE @SubscriberId INT = CAST(RAND() * 100000 AS INT)
WHILE EXISTS (SELECT * FROM dbo.Subscribers AS s WHERE s.SubscriberId = @SubscriberId)
BEGIN 
	SET @SubscriberId = CAST(RAND() * 100000 AS INT)
END

DECLARE @StartDate DATETIME = DATEADD(minute, -ABS((CHECKSUM(NEWID())) % 65530*15), GETDATE())
WHILE @StartDate > GETDATE()
BEGIN
	SET @StartDate = DATEADD(minute, -ABS((CHECKSUM(NEWID()) % 65530*15)), GETDATE())
END

DECLARE @EndDate DATETIME = DATEADD(minute, (CHECKSUM(NEWID()) % 65530*12), GETDATE())
WHILE @EndDate < GETDATE()
BEGIN
	SET @EndDate = DATEADD(minute, (CHECKSUM(NEWID()) % 65530*12), GETDATE())
END
	
INSERT INTO Subscribers
SELECT @SubscriberId
	  ,'Banana-Telecom' AS [ProviderName]
      , CONCAT('Banana-', NEWID()) AS [SubscriberName]
	  ,@StartDate AS [SubscriptionStartDate]
	  ,@EndDate AS [SubscriptionEndDate]
  
SET @counter = @counter+1   
END  



SET @subscribersCount  = 550
SET @counter = 0

WHILE @counter <= @subscribersCount
BEGIN

SET @SubscriberId  = CAST(RAND() * 100000 AS INT)
WHILE EXISTS (SELECT * FROM dbo.Subscribers AS s WHERE s.SubscriberId = @SubscriberId)
BEGIN 
	SET @SubscriberId = CAST(RAND() * 100000 AS INT)
END

SET @StartDate  = DATEADD(minute, -ABS((CHECKSUM(NEWID())) % 65530*14*RAND()), GETDATE())
WHILE @StartDate > GETDATE()
BEGIN
	SET @StartDate = DATEADD(minute, -ABS((CHECKSUM(NEWID()) % 65530*14*RAND())), GETDATE())
END

SET @EndDate  = DATEADD(minute, (CHECKSUM(NEWID()) % 65530*13*RAND()), GETDATE())
WHILE @EndDate < GETDATE()
BEGIN
	SET @EndDate = DATEADD(minute, (CHECKSUM(NEWID()) % 65530*13*RAND()), GETDATE())
END
	
INSERT INTO Subscribers
SELECT @SubscriberId
	  ,'WowNet' AS [ProviderName]
      , CONCAT('Wow-', NEWID()) AS [SubscriberName]
	  ,@StartDate AS [SubscriptionStartDate]
	  ,@EndDate AS [SubscriptionEndDate]
  
SET @counter = @counter+1   
END

INSERT INTO dbo.Products (ProductCode)
VALUES ('KAV'),('KIS'),('KTS'),('KSOS'),('KES')

DECLARE @sbcr_id INT, @start_time DATETIME, @end_time DATETIME

DECLARE subscr_select CURSOR 
	FOR SELECT s.SubscriberId, s.SubscriptionStartDate, s.SubscriptionEndDate
	      FROM dbo.Subscribers AS s
OPEN subscr_select

FETCH NEXT FROM subscr_select
INTO @sbcr_id, @start_time, @end_time

WHILE @@FETCH_STATUS = 0  
	BEGIN
		DECLARE @change_times INT = FLOOR((RAND()*(5-1)+1))	
		DECLARE @count INT = 0
		DECLARE @prod_id INT = -1
		DECLARE @prev_changedate DATETIME

		WHILE @count < @change_times
		BEGIN
			DECLARE @ChangeDate DATETIME = DATEADD(minute, -ABS((CHECKSUM(NEWID())) % 65530*15), GETDATE())
			IF @count = 0
			BEGIN
				SET @ChangeDate = @start_time
			END
			ELSE
			BEGIN
				WHILE @ChangeDate < @start_time OR @ChangeDate > @end_time OR @ChangeDate < @prev_changedate
				BEGIN
					SET @ChangeDate = DATEADD(minute, -ABS((CHECKSUM(NEWID()) % 65530*15)), GETDATE())
				END
			END
			SET @prod_id = (SELECT TOP 1 p.ProductId FROM dbo.Products AS p
			                WHERE p.ProductId != @prod_id
							ORDER BY NEWID())
							
			INSERT INTO dbo.History
			(
				[SubscriberId],
				ProductId,
				ChangeDate
			)
			VALUES
			(
				
				@sbcr_id,
				@prod_id,
				@ChangeDate
			)
			SET @prev_changedate = @ChangeDate
			SET @count = @count + 1
		END
		
	FETCH NEXT FROM subscr_select
	INTO @sbcr_id, @start_time, @end_time
	END
	
CLOSE subscr_select;
DEALLOCATE subscr_select;

END TRY
BEGIN CATCH
      SELECT
             ERROR_LINE() AS ErrorLine,
             ERROR_MESSAGE() AS ErrorMessage; 
      IF @@TRANCOUNT > 0 
             ROLLBACK TRANSACTION; 
END CATCH
              
IF @@TRANCOUNT > 0
       COMMIT TRANSACTION;
GO
