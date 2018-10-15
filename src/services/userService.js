import Boom from 'boom';
import dbFunction from '../dbQueryRunner';
import { log } from 'util';
import commonFunctions from '../utils/commonFunctions.js';
import jwt from 'jsonwebtoken';

/**
 * Get all users.
 *
 * @return {Promise}
 */
export function getAllUser() {
    return User.fetchAll();
}
/**
 * Get all users.
 *
 * @return {Promise}
 */
export function getAllUsers(companyid) {
    return new Promise(function (resolve, reject) {
        const query = `select * from public.get_company_master(companyid:=${(1)})`;
        return dbFunction(query).then(productData => {
            console.log('productData---',productData, typeof productData);
            
            if (!productData) {
                return reject({ statusCode: 404, message: 'No data found.' });
            } else {
                productData = JSON.parse(productData[0].get_company_master);
                return resolve(productData);
            }
        })
        .catch(function (err) {
            return reject(err);
        })
    })

}

/**
 * Get all users.
 *
 * @return {Promise}
 */
export function authenticateUser(data) {
    console.log('data===',typeof data);    
    return new Promise(function (resolve, reject) {
        const query = `select * from public.authenticate_user(user_email:=${commonFunctions.getPostGreParam(data.email, "string")},
        user_password:=${commonFunctions.getPostGreParam(data.password, "string")})`;
        console.log('query===',JSON.stringify(query));
        
        return dbFunction(query).then(productData => {
            productData = JSON.parse(productData[0].authenticate_user);            
            if (productData && productData.data && productData.data.length ==0) {
                return reject(productData);
            } else {                
                let token = jwt.sign({ productData: productData }, process.env.JWT_SECRET, {
                    expiresIn: 86400 // expires in 24 hours
                });
                productData.token = token;
                return resolve(productData);
            }
        })
        .catch(function (err) {
            return reject(err);
        })
    })

 }

/**
 * Get a user.
 *
 * @param  {Number|String}  id
 * @return {Promise}
 */
export function getUser(id) {
    return new User({ id }).fetch().then(user => {
        if (!user) {
            throw new Boom.notFound('User not found');
        }

        return user;
    });
}

/**
 * Create new user.
 *
 * @param  {Object}  user
 * @return {Promise}
 */
export function createUser(user) {
    return new User({ name: user.name }).save().then(user => user.refresh());
}

/**
 * Update a user.
 *
 * @param  {Number|String}  id
 * @param  {Object}         user
 * @return {Promise}
 */
export function updateUser(id, user) {
    return new User({ id }).save({ name: user.name }).then(user => user.refresh());
}

/**
 * Delete a user.
 *
 * @param  {Number|String}  id
 * @return {Promise}
 */
export function deleteUser(id) {
    return new User({ id }).fetch().then(user => user.destroy());
}
