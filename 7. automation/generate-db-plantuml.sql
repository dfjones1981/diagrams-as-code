/*
CHANGE THE BELOW VARIABLE TO LIST ALL TABLES YOU WANT TO APPEAR IN THE RESULTING DIAGRAM
*/
Declare @ObjectsToShow NVarchar(400)=  'dbo.TableOne,dbo.TableTwo' -- comma-delimited list of database objects
Declare @MyPlantUMLStatement varchar(max)
Declare @ObjectsToDo table(Object_ID int primary key)
DECLARE @tableName varchar(100), @Pos int
SET @ObjectsToShow = LTRIM(RTRIM(@ObjectsToShow))+ ','
SET @Pos = CHARINDEX(',', @ObjectsToShow, 1)
SET NOCOUNT ON;
IF REPLACE(@ObjectsToShow, ',', '') <> ''
BEGIN
  WHILE @Pos > 0
    BEGIN
    SET @tableName = LTRIM(RTRIM(LEFT(@ObjectsToShow, @Pos - 1)))
    IF @tableName <> ''
    BEGIN
      INSERT INTO @ObjectsToDo
      VALUES (object_ID(@tableName))
    END
    SET @ObjectsToShow = RIGHT(@ObjectsToShow, LEN(@ObjectsToShow) - @Pos)
    SET @Pos = CHARINDEX(',', @ObjectsToShow, 1)
  END
END 
Select @MyPlantUMLStatement='@startuml database
!define table(x) class x << (T,mistyrose) >> 
!define view(x) class x << (V,lightblue) >> 
!define table(x) class x << (T,mistyrose) >>
!define tr(x) class x << (R,red) >>
!define tf(x) class x << (F,darkorange) >> 
!define af(x) class x << (F,white) >> 
!define fn(x) class x << (F,plum) >> 
!define fs(x) class x << (F,tan) >> 
!define ft(x) class x << (F,wheat) >> 
!define if(x) class x << (F,gaisboro) >> 
!define p(x) class x << (P,indianred) >> 
!define pc(x) class x << (P,lemonshiffon) >> 
!define x(x) class x << (P,linen) >>
hide methods 
hide stereotypes
skinparam classarrowcolor gray
'
SELECT @MyPlantUMLStatement =
  @MyPlantUMLStatement + 'table(' + Object_Schema_Name(allTables.object_id) + '.' + name + ') { 
'
  +
  (
  SELECT DISTINCT 
    c.name + ': ' + t.name
       + CASE WHEN PrimaryKeyColumns.Object_ID IS NOT NULL THEN ' <<pk>>' ELSE '' END
       + CASE WHEN fk.parent_object_id IS NOT NULL THEN ' <<fk>>' ELSE '' END + ' 
'
    FROM sys.columns AS c --give the column names and the data types but no dimensions
      INNER JOIN sys.types AS t
        ON c.user_type_id = t.user_type_id
      LEFT OUTER JOIN sys.foreign_key_columns AS fk
        ON parent_object_id = c.object_id AND parent_column_id = c.column_id
      LEFT OUTER JOIN --the primary keys are a bit awkward to get
           (SELECT i.object_id, column_id
              FROM sys.indexes AS i
                INNER JOIN sys.index_columns AS ic
                  ON ic.object_id = i.object_id AND ic.index_id = i.index_id
                INNER JOIN sys.key_constraints AS k
                  ON k.parent_object_id = ic.object_id AND i.index_id = k.unique_index_id
              WHERE ic.object_id = allTables.object_id AND k.type = 'pk'
           ) AS PrimaryKeyColumns(Object_ID, Column_ID)
        ON c.object_id = PrimaryKeyColumns.Object_ID AND c.column_id = PrimaryKeyColumns.Column_ID
    WHERE c.object_id = allTables.object_id
  FOR XML PATH(''), TYPE
  ).value(N'(./text())[1]', N'varchar(max)')
  + Coalesce('__ trigger __
' +
  (SELECT name + '
'
     FROM sys.triggers
     WHERE parent_id = allTables.object_id
  FOR XML PATH(''), TYPE
  ).value('.', 'varchar(max)'), '') + '}
'
  FROM sys.tables AS allTables
    INNER JOIN @ObjectsToDo AS ObjectsToDo
      ON allTables.object_id = ObjectsToDo.Object_ID;
SELECT @MyPlantUMLStatement =
  @MyPlantUMLStatement + 'view(' + Object_Schema_Name(allViews.object_id) + '.' + name + ') {
'                             +
  (SELECT c.name + ': ' + t.name + '
'
     FROM sys.columns AS c
       INNER JOIN sys.types AS t
         ON c.user_type_id = t.user_type_id
     WHERE c.object_id = allViews.object_id
  FOR XML PATH(''), TYPE
  ).value(N'(./text())[1]', N'varchar(max)') + '}
'
  FROM sys.views AS allViews
    INNER JOIN @ObjectsToDo AS ObjectsToDo
      ON allViews.object_id = ObjectsToDo.Object_ID;
SELECT @MyPlantUMLStatement =
  @MyPlantUMLStatement + RTrim(Lower(Allroutines.type)) + '('
  + Object_Schema_Name(Allroutines.object_id) + '.' + Allroutines.name + ') {
'
  + Coalesce(
  (SELECT p.name + ': ' + Type_Name(p.user_type_id) + '
'
     FROM sys.objects AS o
       INNER JOIN sys.parameters AS p
         ON o.object_id = p.object_id
     WHERE o.object_id = Allroutines.object_id
  FOR XML PATH(''), TYPE
  ).value(N'(./text())[1]', N'varchar(max)'), '') + '}
'
  FROM sys.objects AS Allroutines
    INNER JOIN @ObjectsToDo AS ObjectsToDo
      ON Allroutines.object_id = ObjectsToDo.Object_ID AND type IN
('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'X');
SELECT @MyPlantUMLStatement =
  @MyPlantUMLStatement
  + Coalesce(
  (
  SELECT Coalesce(Object_Schema_Name(referencing_id) + '.', '') + Object_Name(referencing_id)
     + ' -|> ' + referenced_schema_name + '.' + referenced_entity_name + ':References
'
    --AS reference
    FROM sys.sql_expression_dependencies
      INNER JOIN @ObjectsToDo AS ObjectsToDo
        ON referencing_id = ObjectsToDo.Object_ID
      INNER JOIN @ObjectsToDo AS ObjectsToDo2
        ON referenced_id = ObjectsToDo2.Object_ID
    WHERE is_schema_bound_reference = 0
  FOR XML PATH(''), TYPE
  ).value(N'(./text())[1]', N'varchar(max)'), '');
SELECT @MyPlantUMLStatement =
  @MyPlantUMLStatement
  + Coalesce(
  (
  SELECT Object_Schema_Name(parent_object_id) + '.' + Object_Name(parent_object_id) + ' -|> '
     + Object_Schema_Name(referenced_object_id) + '.' + Object_Name(referenced_object_id)
     + ':FK
'
    FROM sys.foreign_keys
      INNER JOIN @ObjectsToDo AS ObjectsToDo
        ON parent_object_id = ObjectsToDo.Object_ID
      INNER JOIN @ObjectsToDo AS ObjectsToDo2
        ON referenced_object_id = ObjectsToDo2.Object_ID
  FOR XML PATH(''), TYPE
  ).value(N'(./text())[1]', N'varchar(max)'), '') + '@enduml';
SELECT @MyPlantUMLStatement;