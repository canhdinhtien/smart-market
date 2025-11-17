const nodemailer = require('nodemailer');
const dotenv = require('dotenv');

dotenv.config();

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL,
        pass: process.env.EMAIL_PASSWORD
    }
});

function createVerificationEmail(code, email) {
    return {
        from: process.env.EMAIL,
        to: email,
        subject: 'Email Verification',
        html: `
            <div style="font-family: Arial, sans-serif; line-height: 1.6;">
                <h2>Hello,</h2>
                <p>Thank you for registering. Please use the following code to verify your email address:</p>
                <div style="font-size: 1.5em; font-weight: bold; margin: 10px 0;">${code}</div>
                <p>If you didn’t request this, you can ignore this email.</p>
                <p>Thanks,<br/>Smart Market</p>
            </div>
        `
    }
}

function sendVerificationEmail(code, email) {
    const option = createVerificationEmail(code, email);
    transporter.sendMail(option, function (error, info) {
        if (error) {
            console.log(error);
        } else {
            console.log('Email sent: ' + info.response);
        }
    });
}

module.exports = { sendVerificationEmail };
