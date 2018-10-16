import Boom from 'boom';
import dbFunction from '../dbQueryRunner';
import { log } from 'util';
import commonFunctions from '../utils/commonFunctions.js';
import nodemailer from 'nodemailer';
import smtpTransport from 'nodemailer-smtp-transport';


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
            console.log('productData---', productData, typeof productData);

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
export function emailOtpInitialSetUp(data) {
    return new Promise(function (resolve, reject) {
        let otp = Math.floor(1000 + Math.random() * 9000);
        console.log(otp);
        const query = `select * from public.initial_company_setup(company_name:=${commonFunctions.getPostGreParam(data.companyName, "string")},
        company_password:=${commonFunctions.getPostGreParam(data.companyPassword, "string")},
        company_email:=${commonFunctions.getPostGreParam(data.companyEmail, "string")},
        company_otp:=${otp},
        company_taxid:=${commonFunctions.getPostGreParam(data.companyTaxid)})`;
        console.log('query===', JSON.stringify(query));

        return dbFunction(query).then(productData => {
            
            productData = JSON.parse(productData[0].company_signup);
            if (productData && productData.data && productData.data.length ==0) {
                return reject(productData);
            } else {                
                let subject = 'CrowdTxt Account Created - Explore your new account now.!';
                let signupURL = "http://localhost:9000/#/login";
                let emailBody = "<html xmlns='http://www.w3.org/1999/xhtml'><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8'/><title>[SUBJECT]</title><style type='text/css'></style><script type='colorScheme' class='swatch active'>{'name':'Default','bgBody':'ffffff','link':'382F2E','color':'999999','bgItem':'ffffff','title':'222222'}</script></head> <body paddingwidth='0' paddingheight='0' style='padding-top: 0; padding-bottom: 0; padding-top: 0; padding-bottom: 0; background-repeat: repeat; width: 100% !important; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; -webkit-font-smoothing: antialiased; background: url(http://localhost:9000/images/banner-bg.jpg) no-repeat center center #dbdee1 ; background-size: cover ; max-height: 600px; min-height: 600px;' offset='0' toppadding='0' leftpadding='0'> <table width='100%' border='0' cellspacing='0' cellpadding='0' class='tableContent bgBody' align='center' style='font-family:Helvetica, Arial,serif; '> <tr><td height='35'></td></tr><tr> <td> <table width='600' border='0' cellspacing='0' cellpadding='0' align='center' class='bgItem' style=' border: 1px solid #ddd; background: rgba(255,255,255,0.5) ;'> <tr> <td width='40'></td><td width='520'> <table width='520' border='0' cellspacing='0' cellpadding='0' align='center'> <tr><td height='75'></td></tr><tr> <td class='movableContentContainer' valign='top'> <div lass='movableContent'> <table width='520' border='0' cellspacing='0' cellpadding='0' align='center'> <tr> <td valign='top' align='center'> <div class='contentEditableContainer contentTextEditable'> <div class='contentEditable'> <img src='http://localhost:9000/images/logo.png'> </div></div></td></tr></table> </div><div class='movableContent'> <table width='520' border='0' cellspacing='0' cellpadding='0' align='center'> <tr><td height='25'></td></tr><tr> <td align='left'> <div class='contentEditableContainer contentTextEditable'> <div class='contentEditable' align='center'> <h2 style='text-align: left; color: #222222 ; font-size: 17px; font-weight: normal;'>Hi " + data.companyName + ", </h2> </div></div></td></tr><tr><td height='1'> </td></tr><tr> <td align='left'> <div class='contentEditableContainer contentTextEditable'> <div class='contentEditable' align='center'> <p style='text-align:left;color:#000;font-size:14px;font-weight:normal;line-height:19px;'>		We have created a new CrowdTxt account for you. <br/><br>"
                    + "		Your account details are: <br/><br>" + "		Email for login: " + data.companyEmail + "<br/><br>		Verification Code: " + otp + " <br/><br>		Activation link :" + "<a href = " + signupURL + "  > Click here..!</a><br/><br>Regards, <br><span style='color:#222222 ;'>CrowdTxt Team</span> </p></div></div></td></tr><tr><td height='55'></td></tr><tr> <td align='center'> <table> <tr> <td align='center' bgcolor='#69C374 ' style='background:#69C374 ; padding:15px 18px;-webkit-border-radius: 4px; -moz-border-radius: 4px; border-radius: 4px;'> <div class='contentEditableContainer contentTextEditable'> <div class='contentEditable' align='center'> <a target='_blank' href='" + signupURL + "' class='link2' style='color:#ffffff ;'>Activation Link</a> </div></div></td></tr></table> </td></tr><tr><td height='30'></td></tr></table> </div></td></tr></table> </td><td width='40'></td></tr></table> </td></tr><tr><td height='88'></td></tr></table> </body> </html>";

                return mailsend(data.companyEmail, subject, emailBody)
                    .then((result) => {
                        if (result && result.code == 200) {
                            return resolve(productData);
                        } else {
                            return reject({ code: 404, message: 'Email faild', error: result });
                        }
                    });
            }
        })
            .catch((err) => {
                return reject(err);
            })
    })
}

/**
* Get company info by Id.
*
* @return {Promise}
*/
export function getCompanyInfoById(companyId) {
    return new Promise(function (resolve, reject) {
        const query = `select * from public.get_company_info(companyid:=${(companyId)})`;
        console.log('query---', query);
        return dbFunction(query).then(productData => {
            console.log('productData---', productData, typeof productData);
            if (!productData) {
                return reject({ statusCode: 404, message: 'No data found.' });
            } else {
                productData = JSON.parse(productData[0].get_company_info);
                return resolve(productData);
            }
        })
            .catch(function (err) {
                return reject(err);
            })
    })

}


/**
* Get get group list.
*
* @return {Promise}
*/
export function getGroupList(loginUserData,queryParam,reqbody) {
    return new Promise(function (resolve, reject) {
        const query = `select * from public.group_list(companyid:=${(23)},page_number:=${(queryParam.page)},page_size:=${(queryParam.limit)},user_limit:=${(queryParam.limit)})`;
        console.log('query--->>>>>>>>>>>>>>', query);
        return dbFunction(query).then(productData => {
            console.log('productData---', productData, typeof productData);
            if (!productData) {
                return reject({ statusCode: 404, message: 'No data found.' });
            } else {
                productData = JSON.parse(productData[0].group_list);
                return resolve(productData);
            }
        })
            .catch(function (err) {
                return reject(err);
            })
    })

}


/**
* saveGroup.
*
* @return {Promise}
*/
export function saveGroup(data) {
    return new Promise(function (resolve, reject) {
        let otp = Math.floor(1000 + Math.random() * 9000);
        console.log(otp);
        const query = `select * from public.save_group(group_name:=${commonFunctions.getPostGreParam(data.groupName, "string")},
        is_public:=${commonFunctions.getPostGreParam(data.isPublic, "string")},
        admin_approved:=${commonFunctions.getPostGreParam(data.adminApproved, "string")},
        is_private:=${commonFunctions.getPostGreParam(data.isPrivate, "string")},
        purpose:=${commonFunctions.getPostGreParam(data.purpose, "string")},
        share_link:=${commonFunctions.getPostGreParam(data.shareLink, "string")},
        company_id:=${loginData.companyid})
        created_by:=${loginData.userid})`;
        console.log('query===', JSON.stringify(query));

        return dbFunction(query).then(productData => {
            console.log('productData===', JSON.stringify(productData));
            productData = JSON.parse(productData[0].save_group);
            if (productData && productData.data && productData.data.length == 0) {
                return reject(productData);
            } else {
                let subject = 'CrowdTxt Account Created - Explore your new account now.!';
                let signupURL = "http://localhost:9000/#/login";
                let emailBody = "<html xmlns='http://www.w3.org/1999/xhtml'><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8'/><title>[SUBJECT]</title><style type='text/css'></style><script type='colorScheme' class='swatch active'>{'name':'Default','bgBody':'ffffff','link':'382F2E','color':'999999','bgItem':'ffffff','title':'222222'}</script></head> <body paddingwidth='0' paddingheight='0' style='padding-top: 0; padding-bottom: 0; padding-top: 0; padding-bottom: 0; background-repeat: repeat; width: 100% !important; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; -webkit-font-smoothing: antialiased; background: url(http://localhost:9000/images/banner-bg.jpg) no-repeat center center #dbdee1 ; background-size: cover ; max-height: 600px; min-height: 600px;' offset='0' toppadding='0' leftpadding='0'> <table width='100%' border='0' cellspacing='0' cellpadding='0' class='tableContent bgBody' align='center' style='font-family:Helvetica, Arial,serif; '> <tr><td height='35'></td></tr><tr> <td> <table width='600' border='0' cellspacing='0' cellpadding='0' align='center' class='bgItem' style=' border: 1px solid #ddd; background: rgba(255,255,255,0.5) ;'> <tr> <td width='40'></td><td width='520'> <table width='520' border='0' cellspacing='0' cellpadding='0' align='center'> <tr><td height='75'></td></tr><tr> <td class='movableContentContainer' valign='top'> <div lass='movableContent'> <table width='520' border='0' cellspacing='0' cellpadding='0' align='center'> <tr> <td valign='top' align='center'> <div class='contentEditableContainer contentTextEditable'> <div class='contentEditable'> <img src='http://localhost:9000/images/logo.png'> </div></div></td></tr></table> </div><div class='movableContent'> <table width='520' border='0' cellspacing='0' cellpadding='0' align='center'> <tr><td height='25'></td></tr><tr> <td align='left'> <div class='contentEditableContainer contentTextEditable'> <div class='contentEditable' align='center'> <h2 style='text-align: left; color: #222222 ; font-size: 17px; font-weight: normal;'>Hi " + data.companyName + ", </h2> </div></div></td></tr><tr><td height='1'> </td></tr><tr> <td align='left'> <div class='contentEditableContainer contentTextEditable'> <div class='contentEditable' align='center'> <p style='text-align:left;color:#000;font-size:14px;font-weight:normal;line-height:19px;'>		We have created a new CrowdTxt account for you. <br/><br>"
                    + "		Your account details are: <br/><br>" + "		Email for login: " + data.companyEmail + "<br/><br>		Verification Code: " + otp + " <br/><br>		Activation link :" + "<a href = " + signupURL + "  > Click here..!</a><br/><br>Regards, <br><span style='color:#222222 ;'>CrowdTxt Team</span> </p></div></div></td></tr><tr><td height='55'></td></tr><tr> <td align='center'> <table> <tr> <td align='center' bgcolor='#69C374 ' style='background:#69C374 ; padding:15px 18px;-webkit-border-radius: 4px; -moz-border-radius: 4px; border-radius: 4px;'> <div class='contentEditableContainer contentTextEditable'> <div class='contentEditable' align='center'> <a target='_blank' href='" + signupURL + "' class='link2' style='color:#ffffff ;'>Activation Link</a> </div></div></td></tr></table> </td></tr><tr><td height='30'></td></tr></table> </div></td></tr></table> </td><td width='40'></td></tr></table> </td></tr><tr><td height='88'></td></tr></table> </body> </html>";

                return mailsend(data.companyEmail, subject, emailBody)
                    .then((result) => {
                        if (result && result.code == 200) {
                            return resolve(productData);
                        } else {
                            return reject({ status : 404, message: 'Email faild', error: result });
                        }
                    });
            }
        })
            .catch((err) => {
                return reject(err);
            })
    })
}
// /**
//  * Get a user.
//  *
//  * @param  {Number|String}  id
//  * @return {Promise}
//  */
// export function getUser(id) {
//     return new User({ id }).fetch().then(user => {
//         if (!user) {
//             throw new Boom.notFound('User not found');
//         }

//         return user;
//     });
// }

// /**
//  * Create new user.
//  *
//  * @param  {Object}  user
//  * @return {Promise}
//  */
// export function createUser(user) {
//     return new User({ name: user.name }).save().then(user => user.refresh());
// }

// /**
//  * Update a user.
//  *
//  * @param  {Number|String}  id
//  * @param  {Object}         user
//  * @return {Promise}
//  */
// export function updateUser(id, user) {
//     return new User({ id }).save({ name: user.name }).then(user => user.refresh());
// }

// /**
//  * Delete a user.
//  *
//  * @param  {Number|String}  id
//  * @return {Promise}
//  */
// export function deleteUser(id) {
//     return new User({ id }).fetch().then(user => user.destroy());
// }

