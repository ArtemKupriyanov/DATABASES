--1 задание
--основная идея: заметим, что данные в таблице history упорядочены. Т.е.  если мы сделаем inner join history с самой же, но со 
--сдвинутым id на 1, то получим нужное разбиение на интервалы, в которых пользователь использует один продукт
--замечание: при таком join'e последняя строчка буде ссджойнена с null строкой, но последняя строка, из-за упорядоченности,
--есть последний интервал последнего пользователя, т.е. для этой строки FinishDate будет совпадать с  SubscriptionEndDate
--далее обычный запрос. Еще использовал функцию EOMONTH из transact-sql, которая возвращает дату последнего дня месяца для указанной даты. 
SELECT 
	[ResponseTable].*, DATEDIFF(m, ResponseTable.StartDate, ResponseTable.FinishDate) AS LifeTime 
FROM
(
	SELECT [Subscribers].[ProviderName], [Subscribers].[SubscriberName], [updHistory].[ProductCode], 
		EOMONTH([updHistory].[ChangeDate]) AS StartDate, 
		EOMONTH(IIF([updHistory].[SubscriberId] = [updHistory].[SubscriberId2], ChangeDate2, [Subscribers].[SubscriptionEndDate])) AS FinishDate
	FROM
		[Subscribers]
		INNER JOIN
		(
		SELECT
			[twoHistory].[HistoryId], [Products].[ProductCode], [twoHistory].[SubscriberId], [twoHistory].[SubscriberId2],
			[twoHistory].[ChangeDate], [twoHistory].[ChangeDate2]
		FROM
			[Products]
			INNER JOIN 
			(
			SELECT
				T1.*, T2.SubscriberId AS SubscriberId2, T2.ChangeDate AS ChangeDate2
			FROM
				[History] AS T1 LEFT JOIN [History] AS T2
			ON
				T1.HistoryId = T2.HistoryId - 1
			) 
		AS [twoHistory]
		ON
			[Products].[ProductId] = [twoHistory].[ProductId]
		) 
	AS [updHistory]
	ON
		[Subscribers].[SubscriberId] = [updHistory].[SubscriberId]
	) 
AS ResponseTable

--за основу взято задание 1, а именно, заблица Table1stTask - таблица из 1ого задания
--просто сделаем group by по 4м столбцам таблицы Table1stTask: по названию провайдера (ProviderName), по месяцу начала подписки (StartDate), 
--по коду продукта (ProductCode) и по времени "жизни" подписки (LifeTime) именно это и означает столбец SubscribersCount
--тогда легко получить BillingIntervals, как проиведение SubscribersCount на время "жизни" подписки
SELECT 
	Table1stTask.ProviderName, Table1stTask.ProductCode, Table1stTask.StartDate, Table1stTask.LifeTime, 
	COUNT(*) AS SubscribersCount,
	COUNT(*) * Table1stTask.LifeTime AS BillingIntervals
FROM
(
	SELECT [ResponseTable].*, DATEDIFF(m, ResponseTable.StartDate, ResponseTable.FinishDate) AS LifeTime FROM
	(
		SELECT 
			[Subscribers].[ProviderName], [Subscribers].[SubscriberName], [updHistory].[ProductCode],
			EOMONTH([updHistory].[ChangeDate]) AS StartDate,
			EOMONTH(IIF([updHistory].[SubscriberId] = [updHistory].[SubscriberId2], ChangeDate2, [Subscribers].[SubscriptionEndDate])) AS FinishDate
		FROM
			[Subscribers]
			INNER JOIN
			(
			SELECT
				[twoHistory].[HistoryId], [Products].[ProductCode], [twoHistory].[SubscriberId], [twoHistory].[SubscriberId2], 
				[twoHistory].[ChangeDate], [twoHistory].[ChangeDate2]
			FROM
				[Products]
				INNER JOIN
				(
				SELECT
					T1.*, T2.SubscriberId AS SubscriberId2, T2.ChangeDate AS ChangeDate2
				FROM
					[History] AS T1 LEFT JOIN [History] AS T2
				ON
					T1.HistoryId = T2.HistoryId - 1
				) 
			AS [twoHistory]
			ON
				[Products].[ProductId] = [twoHistory].[ProductId]
			) 
		AS [updHistory]
		ON
			[Subscribers].[SubscriberId] = [updHistory].[SubscriberId]
		) 
	AS ResponseTable
	) 
AS Table1stTask
GROUP BY 
	Table1stTask.ProviderName, Table1stTask.StartDate, Table1stTask.ProductCode, Table1stTask.LifeTime