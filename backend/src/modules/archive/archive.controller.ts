import { Request, Response, NextFunction } from 'express';
import { archiveService } from './archive.service';
import { sendSuccess } from '../../common/utils/response';

export class ArchiveController {
  async getArchive(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await archiveService.getArchive(req.user!.userId);
      sendSuccess(res, data);
    } catch (error) {
      next(error);
    }
  }
}

export const archiveController = new ArchiveController();
