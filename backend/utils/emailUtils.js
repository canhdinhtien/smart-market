const { Resend } = require('resend');
const dotenv = require('dotenv');

dotenv.config();

const resend = new Resend(process.env.RESEND_API_KEY);

function createVerificationEmail(code) {
    return `
        <div style="font-family: Arial, sans-serif; line-height: 1.6;">
            <h2>Hello,</h2>
            <p>Thank you for registering. Please use the following code to verify your email address:</p>
            <div style="font-size: 1.5em; font-weight: bold; margin: 10px 0;">${code}</div>
            <p>If you didn't request this, you can ignore this email.</p>
            <p>Thanks,<br/>Smart Market</p>
        </div>
    `;
}

function createPasswordResetEmail(code) {
    return `
        <div style="font-family: Arial, sans-serif; line-height: 1.6;">
            <h2>Password Reset Request</h2>
            <p>You requested to reset your password. Use the following code to reset it:</p>
            <div style="font-size: 1.5em; font-weight: bold; margin: 10px 0;">${code}</div>
            <p>This code expires in 15 minutes.</p>
            <p>If you didn't request this, please ignore this email or contact support if you're concerned.</p>
            <p>Thanks,<br/>Smart Market</p>
        </div>
    `;
}

const sendVerificationEmail = async (code, email) => {
    try {
        const { data, error } = await resend.emails.send({
            from: process.env.EMAIL,
            to: [email],
            subject: 'Email Verification',
            html: createVerificationEmail(code),
        });

        if (error) {
            console.error('Error sending email:', error);
            return;
        }

        console.log('Email sent successfully:', data);
    } catch (err) {
        console.error('Unexpected error sending email:', err);
    }
};

const sendPasswordResetEmail = async (code, email) => {
    try {
        const { data, error } = await resend.emails.send({
            from: process.env.EMAIL,
            to: [email],
            subject: 'Password Reset Request',
            html: createPasswordResetEmail(code),
        });

        if (error) {
            console.error('Error sending password reset email:', error);
            throw new Error('Failed to send password reset email');
        }

        console.log('Password reset email sent successfully:', data);
    } catch (err) {
        console.error('Unexpected error sending password reset email:', err);
        throw err;
    }
};

module.exports = { sendVerificationEmail, sendPasswordResetEmail };
