import nodemailer from 'nodemailer';
import { config } from '../../config';
import { logger } from '../../common/logger';

class EmailService {
  private transporter: nodemailer.Transporter | null = null;

  constructor() {
    if (config.SMTP_HOST && config.SMTP_USER && config.SMTP_PASSWORD) {
      this.transporter = nodemailer.createTransport({
        host: config.SMTP_HOST,
        port: config.SMTP_PORT,
        secure: config.SMTP_PORT === 465,
        auth: {
          user: config.SMTP_USER,
          pass: config.SMTP_PASSWORD,
        },
      });
      logger.info('SMTP Email transporter initialized');
    } else {
      logger.info('SMTP settings not configured; emails will log to console in development');
    }
  }

  async sendEmail(to: string, subject: string, html: string, text?: string): Promise<boolean> {
    if (!this.transporter) {
      logger.info(`[MOCK EMAIL] To: ${to} | Subject: ${subject}\n${text || html}`);
      return true;
    }

    try {
      await this.transporter.sendMail({
        from: config.SMTP_FROM,
        to,
        subject,
        html,
        text: text || html.replace(/<[^>]*>?/gm, ''),
      });
      logger.info(`Email sent successfully to ${to}`);
      return true;
    } catch (err) {
      logger.error(`Failed to send email to ${to}:`, err);
      return false;
    }
  }

  async sendWelcomeEmail(to: string, name: string): Promise<boolean> {
    const subject = 'Welcome to FinishX — One Journey. Full Focus.';
    const html = `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; color: #153B35;">
        <h2>Welcome to FinishX, ${name}!</h2>
        <p>You have taken the first step toward finishing what truly matters.</p>
        <p>Our philosophy is simple: <strong>One Journey. Full Focus.</strong></p>
        <p>Pick one journey, sign your commitment schedule, and let your accountability group help you see it through.</p>
        <p style="margin-top: 32px;">— The FinishX Team</p>
      </div>
    `;
    return this.sendEmail(to, subject, html);
  }
}

export const emailService = new EmailService();
