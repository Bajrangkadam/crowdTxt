import config from './knexfile';
import pg from 'pg';

/**
  * CALL DATABASE FUNCTION.
  *
  */
function queryRunner(qry) { 
    return new Promise((resolve, reject) => {
        if (qry === null) {
            console.log('Error in query string: ' + JSON.stringify(qry));
            return reject({
                    code: 400,
                    error: 'No Query Found'
                });
        } else {
            var pool = new pg.Pool(config);
            pool.connect()
                .then(client => {
                    client.query(qry)
                        .then(res => {                            
                            client.release();
                            client.end();
                            resolve(res.rows);
                        })
                        .catch(e => {
                            client.release();
                            client.end();
                            console.error('query error in', e.message, e.stack);
                            //deferred.reject(e.message);
                            reject({
                                code: 400,
                                error: 'Internal Structure Error'
                            });
                        });
                }).catch(e => {
                    console.error('query error out', e.message, e.stack);
                    //deferred.reject(e.message);
                    reject({
                        code: 500,
                        error: 'Internal Connection Error'
                    });
                });
        }

    })
}

/* Get data from postgresql server */
function select(qry) {
    var deferred = q.defer();
    if (qry === null) {
        log.e('Error in query string: ' + JSON.stringify(qry));
        return deferred.reject('No Query Found');
    }
    var pool = new pg.Pool(config);
    pool.connect()
        .then(client => {
            client.query(qry)
                .then(res => {
                    client.release();
                    client.end();
                    deferred.resolve(res.rows);
                })
                .catch(e => {
                    client.release();
                    client.end();
                    console.error('query error in', e.message, e.stack);
                    //deferred.reject(e.message);
                    deferred.reject({
                        code: 200,
                        error: 'Internal Structure Error'
                    });
                });
        }).catch(e => {
            console.error('query error out', e.message, e.stack);
            //deferred.reject(e.message);
            deferred.reject({
                code: 200,
                error: 'Internal Connection Error'
            });
        });
    return deferred.promise;
}
module.exports = queryRunner