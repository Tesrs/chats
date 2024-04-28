import prisma from '@/prisma/prisma';
import { Prisma } from '@prisma/client';
import Decimal from 'decimal.js';

export interface CreateChatMessage {
  userId: string;
  chatId: string;
  parentId?: string | null;
  messages: string;
  calculatedPrice: Decimal;
  tokenUsed: number;
}

export class ChatMessagesManager {
  static async findByUserMessageId(id: string, userId: string) {
    return await prisma.chatMessages.findUnique({
      where: { id, AND: { userId } },
    });
  }
  static async create(params: CreateChatMessage) {
    return await prisma.chatMessages.create({ data: { ...params } });
  }

  static async findUserMessageByChatId(userId: string, chatId: string) {
    let where: Prisma.ChatMessagesWhereInput = {
      chatId,
    };
    return await prisma.chatMessages.findMany({ where });
  }

  static async delete(id: string) {
    return await prisma.chatMessages.delete({ where: { id } });
  }

  static async checkIsFirstChat(chatId: string) {
    const message = await prisma.chatMessages.findFirst({ where: { chatId } });
    return !!message;
  }
}
