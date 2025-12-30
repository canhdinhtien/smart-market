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
            <p>If you didn’t request this, you can ignore this email.</p>
            <p>Thanks,<br/>Smart Market</p>
        </div>
    `;
}

const sendVerificationEmail = async (code, email) => {
    try {
        const { data, error } = await resend.emails.send({
            from: 'onboarding@resend.dev',
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

module.exports = { sendVerificationEmail };
