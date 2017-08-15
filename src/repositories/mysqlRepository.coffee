
crypto = require('crypto')
mysqlConf = require('../configs/mysql') 
brokerConf = require('../configs/broker') 
mysql = require('mysql')

# job queue CRUD implementation for MySQL
class MySQLRepository

  constructor: () ->
    @pool = null
    @initMysqlRepo()
    .then((resp) =>
      log.i('mysql repo ready')

      @createJobId()
    )
    .catch((err) =>
      log.e(err) 
    )

  _queryOps: (queryOps) =>
    if @pool == null 
      @pool = mysql.createPool(mysqlConf)
    return new Promise((resolve, reject) =>
      @pool.getConnection((err, con) =>
        if err != null 
          return reject(err) 
        queryOps(con)
        .then((resp) =>
          con.release()
          resolve(resp)
        )
        .catch((err) =>
          con.release()
          reject(err)
        )
      )
    )

  initMysqlRepo: () =>
    query = 
    """
    CREATE TABLE IF NOT EXISTS jobshop_job (
      no INT PRIMARY KEY AUTO_INCREMENT,
      job_id VARCHAR(100) NOT NULL UNIQUE, 
      job_payload VARCHAR(1000) NOT NULL
    )
    """
    return @_queryOps((con) =>
      return new Promise((resolve, reject) =>
        con.query(query, (err, resp) =>
          if err != null 
            return reject(err) 
          resolve(resp) 
        )
      )
    )

  # create new unique job id 
  # in this Repository
  createJobId: () =>
    query = 
    """
    SELECT 
      no 
    FROM 
      jobshop_job 
    ORDER BY 
      no DESC 
    LIMIT 1 
    """
    return @_queryOps((con) =>
      return new Promise((resolve, reject) =>
        con.query(query, (err, rows) =>
          if err != null 
            return reject(err) 
          currentNo = 0
          if rows.length > 0
            currentNo = rows[0].no
          currentNo++
          jobId = crypto.createHash('sha256').update(currentNo).digest('hex')
          resolve(jobId)
        )
      )
    )

  # enqueue new job with payload, 
  # returns with unique job ID 
  addJob: (jobPayload) =>
    query = 
    """
    INSERT INTO 
      jobshop_job 
    SET
      job_id=?,
      job_payload=? 
    """
    return @_queryOps((con) =>
      return new Promise((resolve, reject) =>
        @createJobId()
        .then((newJobId) =>
          params = [
            newJobId,
            JSON.stringify(jobPayload)
          ]
          con.query(query, params, (err, resp) =>
            if err != null 
              return reject(err)
            resolve(resp)
          )
        ) 
        .catch((err) =>
          reject(err)
        )
      )
    )

  # get one job to do.
  fetchJobTodo: () =>
    return new Promise((resolve, reject) =>
      
    )

  # make job to success 
  makeJobSuccess: (jobId) =>
    return new Promise((resolve, reject) =>
      
    )

  # make job to failure
  makeJobFail: (jobId) =>
    return new Promise((resolve, reject) =>
      
    )

  # returns job queue elements with condition
  getJobs: (condition) =>
    return new Promise((resolve, reject) =>

    )

  # returns job failure logs.
  getJobFails: (condition) =>
    return new Promise((resolve, reject) =>

    )

instance = null
module.exports = () ->
  if instance == null 
    instance = new MySQLRepository() 
  return instance