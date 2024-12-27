import { useEffect, useReducer, useState } from 'react';

import { useRouter } from 'next/router';

import { useCreateReducer } from '@/hooks/useCreateReducer';
import useTranslation from '@/hooks/useTranslation';

import { getPathChatId } from '@/utils/chats';
import { findSelectedMessageByLeafId } from '@/utils/message';
import { getSettings } from '@/utils/settings';

import { ChatStatus, IChat } from '@/types/chat';
import { IChatMessage } from '@/types/chatMessage';
import { ChatResult, GetChatsParams } from '@/types/clientApis';

import Spinner from '@/components/Spinner/Spinner';

import {
  setChatPaging,
  setChats,
  setIsChatsLoading,
  setSelectedChat,
  setStopIds,
} from '../../_actions/chat.actions';
import {
  setMessages,
  setSelectedMessages,
} from '../../_actions/message.actions';
import { setModelMap, setModels } from '../../_actions/model.actions';
import { setDefaultPrompt, setPrompts } from '../../_actions/prompt.actions';
import {
  setShowChatBar,
  setShowPromptBar,
} from '../../_actions/setting.actions';
import HomeContext, {
  HandleUpdateChatParams,
  HomeInitialState,
  initialState,
} from '../../_contexts/home.context';
import chatReducer, { chatInitialState } from '../../_reducers/chat.reducer';
import messageReducer, {
  messageInitialState,
} from '../../_reducers/message.reducer';
import modelReducer, { modelInitialState } from '../../_reducers/model.reducer';
import promptReducer, {
  promptInitialState,
} from '../../_reducers/prompt.reducer';
import settingReducer, {
  settingInitialState,
} from '../../_reducers/setting.reducer';
import Chat from '../Chat/Chat';
import Chatbar from '../Chatbar/Chatbar';
import PromptBar from '../Promptbar/Promptbar';

import {
  getChatsByPaging,
  getDefaultPrompt,
  getUserMessages,
  getUserModels,
  getUserPromptBrief,
  postChats,
  stopChat,
} from '@/apis/clientApis';

const HomeContent = () => {
  const router = useRouter();
  const { t } = useTranslation();
  const [chatState, chatDispatch] = useReducer(chatReducer, chatInitialState);
  const [messageState, messageDispatch] = useReducer(
    messageReducer,
    messageInitialState,
  );
  const [modelState, modelDispatch] = useReducer(
    modelReducer,
    modelInitialState,
  );
  const [settingState, settingDispatch] = useReducer(
    settingReducer,
    settingInitialState,
  );
  const [promptState, promptDispatch] = useReducer(
    promptReducer,
    promptInitialState,
  );

  const { chats, stopIds } = chatState;
  const { models } = modelState;
  const { showPromptBar } = settingState;
  const [isPageLoading, setIsPageLoading] = useState(true);

  const contextValue = useCreateReducer<HomeInitialState>({
    initialState,
  });

  const selectChatMessage = (
    messages: IChatMessage[],
    leafMessageId?: string,
  ) => {
    messageDispatch(setMessages(messages));
    let leafMsgId = leafMessageId;
    if (!leafMsgId) {
      const messageCount = messages.length - 1;
      leafMsgId = messages[messageCount].id;
    }
    const selectedMessageList = findSelectedMessageByLeafId(
      messages,
      leafMsgId,
    );
    messageDispatch(setSelectedMessages(selectedMessageList));
  };

  const prepareChat = (chatList: ChatResult[], selectChatId?: string) => {
    let chatId = selectChatId || getPathChatId(router.asPath);
    if (chatList.length > 0) {
      const foundChat = chatList.find((x) => x.id === chatId) || chatList[0];
      return foundChat;
    }
    return undefined;
  };

  const supplyChatProperty = (chat: ChatResult): IChat => {
    return { ...chat, status: ChatStatus.None };
  };

  const selectChat = (chatList: ChatResult[], chatId?: string) => {
    const chat = prepareChat(chatList, chatId);
    if (chat) {
      chatDispatch(setSelectedChat(supplyChatProperty(chat)));

      getUserMessages(chat.id).then((data) => {
        if (data.length > 0) {
          selectChatMessage(data, chat.leafMessageId);
        } else {
          messageDispatch(setMessages([]));
          messageDispatch(setSelectedMessages([]));
        }
      });
    }
  };

  const handleNewChat = () => {
    postChats({ title: t('New Conversation') }).then((data) => {
      chatDispatch(setChats([data, ...chats]));
      chatDispatch(setSelectedChat(supplyChatProperty(data)));
      messageDispatch(setMessages([]));
      messageDispatch(setSelectedMessages([]));

      const chatId = data.id;
      router.push('#/' + chatId);
    });
  };

  const handleSelectChat = (chat: IChat) => {
    chatDispatch(setSelectedChat(chat));
    getUserMessages(chat.id).then((data) => {
      if (data.length > 0) {
        selectChatMessage(data, chat.leafMessageId);
      } else {
        messageDispatch(setMessages([]));
        messageDispatch(setSelectedMessages([]));
      }
    });
    router.push('#/' + chat.id);
  };

  const hasModel = () => {
    return models?.length > 0;
  };

  const handleUpdateChat = (
    chats: ChatResult[],
    id: string,
    params: HandleUpdateChatParams,
  ) => {
    const chatList = chats.map((x) => {
      if (x.id === id) return { ...x, ...params };
      return x;
    });
    chatDispatch(setChats(chatList));
  };

  const handleDeleteChat = (id: string) => {
    const chatList = chats.filter((x) => {
      return x.id !== id;
    });
    chatDispatch(setChats(chatList));

    if (chatList.length > 0) {
      selectChat(chatList, chatList[0].id);
    } else {
      chatDispatch(setSelectedChat(undefined));
    }
  };

  const handleStopChats = () => {
    let p = [] as any[];
    stopIds.forEach((id) => {
      p.push(stopChat(id));
    });
    Promise.all(p).then(() => {
      chatDispatch(setStopIds([]));
    });
  };

  const getChats = async (params: GetChatsParams, isAppend = true) => {
    const { page, pageSize } = params;
    getChatsByPaging(params).then((data) => {
      const { rows, count } = data || { rows: [], count: 0 };
      let chatList = rows;
      if (isAppend) {
        chatList = chats.concat(rows);
      }
      chatDispatch(setChats(chatList));
      chatDispatch(setChatPaging({ count, page, pageSize }));
    });
  };

  const loadFirstChats = async () => {
    const params = { page: 1, pageSize: 50 };
    getChatsByPaging(params).then((data) => {
      const { rows, count } = data || { rows: [], count: 0 };
      let chatList = rows;

      chatDispatch(setChats(chatList));
      chatDispatch(
        setChatPaging({ count, page: params.page, pageSize: params.pageSize }),
      );
      selectChat(rows);
    });
  };

  useEffect(() => {
    setIsPageLoading(true);
    const { showChatBar, showPromptBar } = getSettings();
    settingDispatch(setShowChatBar(showChatBar));
    settingDispatch(setShowPromptBar(showPromptBar));
  }, []);

  useEffect(() => {
    chatDispatch(setIsChatsLoading(true));
    getUserModels().then(async (modelList) => {
      modelDispatch(setModels(modelList));
      modelDispatch(setModelMap(modelList));

      if (modelList && modelList.length > 0) {
        getDefaultPrompt().then((data) => {
          promptDispatch(setDefaultPrompt(data));
        });
      }

      await loadFirstChats();
      chatDispatch(setIsChatsLoading(false));
    });

    getUserPromptBrief().then((data) => {
      promptDispatch(setPrompts(data));
    });
    setTimeout(() => setIsPageLoading(false), 800);
  }, []);

  // useEffect(() => {
  //   const handlePopState = (event: PopStateEvent) => {
  //     const chatId = getPathChatId(event.state?.as || '');
  //     selectChat(chats, chatId);
  //   };

  //   window.addEventListener('popstate', handlePopState);

  //   return () => {
  //     window.removeEventListener('popstate', handlePopState);
  //   };
  // }, [chats]);

  return (
    <HomeContext.Provider
      value={{
        ...contextValue,
        state: {
          ...contextValue.state,
          ...chatState,
          ...messageState,
          ...modelState,
          ...settingState,
          ...promptState,
        },
        chatDispatch: chatDispatch,
        messageDispatch: messageDispatch,
        modelDispatch: modelDispatch,
        settingDispatch: settingDispatch,
        promptDispatch: promptDispatch,

        handleNewChat,
        handleStopChats,

        handleSelectChat,
        handleUpdateChat,
        handleDeleteChat,
        hasModel,
        getChats,
      }}
    >
      {isPageLoading && (
        <div
          className={`fixed top-0 left-0 bottom-0 right-0 bg-background z-50 text-center text-[12.5px]`}
        >
          <div className="fixed w-screen h-screen top-1/2">
            <div className="flex justify-center">
              <Spinner className="text-gray-500 dark:text-gray-50" />
            </div>
          </div>
        </div>
      )}
      {!isPageLoading && (
        <div className={'flex h-screen w-screen flex-col text-sm'}>
          <div className="flex h-full w-full bg-background">
            <Chatbar />
            <div className="flex w-full">
              <Chat />
            </div>
            {showPromptBar && <PromptBar />}
          </div>
        </div>
      )}
    </HomeContext.Provider>
  );
};

export default HomeContent;
