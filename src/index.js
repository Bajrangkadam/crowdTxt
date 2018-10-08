import 'babel-polyfill';

import './env';
import cors from 'cors';
import path from 'path';
import helmet from 'helmet';
import morgan from 'morgan';
import express from 'express';
import routes from './routes';
import favicon from 'serve-favicon';
import logger from './utils/logger';
import bodyParser from 'body-parser';
import compression from 'compression';
import json from './middlewares/json';
import * as errorHandler from './middlewares/errorHandler';

const app = express();

const APP_PORT =
  (process.env.NODE_ENV === 'test' ? process.env.TEST_APP_PORT : process.env.APP_PORT) || process.env.PORT || '3000';
const APP_HOST = process.env.APP_HOST || '0.0.0.0';

app.set('port', APP_PORT);
app.set('host', APP_HOST);

app.locals.title = process.env.APP_NAME;
app.locals.version = process.env.APP_VERSION;

app.use(favicon(path.join(__dirname, '/../public', 'favicon.ico')));
app.use(cors());
app.use(helmet());
app.use(compression());
app.use(morgan('dev'));
app.use(bodyParser.json());
app.use(errorHandler.bodyParser);
app.use(json);
app.use(function (request, res, next) {
	if (request.url.indexOf('login') > -1) {
		next();
	} else {
		verifyAccessToken(request, res, next);
	}
});

function verifyAccessToken(req,res,next){
	try{
		if(!(req.headers['x-access-token'])){
			//console.log('Darshan KHamr inside if');
			res.status(401).statusMessage = 'Bad Request';statusObj.code = 401; statusObj.status = "failed"; 
					statusObj.content="";statusObj.role="";statusObj.branch="";
					statusObj.message = 'Request should have required headers';
					res.send(statusObj);
					res.end();
		}
		logger.debug(authBasePath+'/verifyToken');
		const getTokenOptions = {  
			    url: authBasePath+'/verifyToken?apikey='+configApikey,
			    method: 'POST',
			    headers: {
			    	'Accept': 'application/json',
			        'Accept-Charset': 'utf-8',
					'content-type' : 'application/json'
			    }, body:JSON.stringify({token:req.headers['x-access-token'],adToken:req.headers['x-refresh-token'],role:req.headers['roleparam']}),
            	 rejectUnauthorized: false
			};
			request(getTokenOptions, function(err, response, body) {
				logger.error(err);
				//console.log(response.body);
				if(!err && response.statusCode == 200){
					logger.info('TOKEN IS VERIFIED')
					//logger.debug(req.headers['x-access-token'] +'*********'+JSON.parse(response.body).token);
					if(JSON.parse(response.body).token && req.headers['x-access-token'] !=JSON.parse(response.body).token ){
						res.setHeader('x-access-token', JSON.parse(response.body).token);
						//console.log('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');
						//console.log(res)
					}
					next();
				} else{
					logger.info('TOKEN IS NOTTTTT VERIFIED');
					var statusObj={};
					res.status(401).statusMessage = 'Bad Request';statusObj.code = 401; statusObj.status = "failed"; 
					statusObj.content="";statusObj.role="";statusObj.branch="";
					statusObj.message = 'Error while verifying Token, error-message';
					res.send(statusObj);
					res.end();
				}
				
			});
	}catch(err){
		var statusObj={};
		res.status(401).statusMessage = 'Bad Request';/*statusObj.code = 401; statusObj.status = "failed"; 
					statusObj.content="";statusObj.role="";statusObj.branch="";
					statusObj.message = 'Error while verifying Token, error-message';*/
					//res.send(statusObj);
					res.end();
	}
	logger.info("### verifyAccessToken in tokenController - End ###");
	
}

// Everything in the public folder is served as static content
app.use(express.static(path.join(__dirname, '/../public')));

// API Routes
app.use('/crowdtxt/api', routes);

// Error Middlewares
app.use(errorHandler.genericErrorHandler);
app.use(errorHandler.methodNotAllowed);

app.listen(app.get('port'), app.get('host'), () => {
  logger.log('info', `Server started at http://${app.get('host')}:${app.get('port')}`);
});

export default app;
