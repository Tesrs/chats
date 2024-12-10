'use client';

import { useEffect } from 'react';

import { useRouter } from 'next/router';

import useTranslation from '@/hooks/useTranslation';

import { Nav } from '@/pages/admin/_components/Nav/Nav';
import {
  IconFiles,
  IconIdBadge,
  IconKey,
  IconMessages,
  IconNotes,
  IconSettings,
  IconSettingsCog,
  IconShieldLock,
  IconUserCog,
  IconUsers,
} from '@/components/Icons/index';

const AdminLayout = ({
  children,
}: {
  children: React.ReactNode;
  className?: string;
}) => {
  const router = useRouter();
  const { t } = useTranslation();

  const menus = [
    // {
    //   url: '/admin/dashboard',
    //   icon: (stroke?: string) => {
    //     return <IconChartPie stroke={stroke} />;
    //   },
    //   title: t('Dashboard'),
    // },
    {
      url: '/admin/model-keys',
      icon: (stroke?: string) => {
        return <IconKey stroke={stroke} />;
      },
      title: t('Model Keys'),
    },
    {
      url: '/admin/models',
      icon: (stroke?: string) => {
        return <IconSettingsCog stroke={stroke} />;
      },
      title: t('Model Configs'),
    },
    {
      url: '/admin/users',
      icon: (stroke?: string) => {
        return <IconUsers stroke={stroke} />;
      },
      title: t('User Management'),
    },
    {
      url: '/admin/messages',
      icon: (stroke?: string) => {
        return <IconMessages stroke={stroke} />;
      },
      title: t('User Messages'),
    },
    {
      url: '/admin/file-service',
      icon: (stroke?: string) => {
        return <IconFiles stroke={stroke} />;
      },
      title: t('File Service'),
    },
    {
      url: '/admin/login-service',
      icon: (stroke?: string) => {
        return <IconShieldLock stroke={stroke} />;
      },
      title: t('Login Service'),
    },
    // {
    //   url: '/admin/pay-service',
    //   icon: (stroke?: string) => {
    //     return <IconCreditCard stroke={stroke} />;
    //   },
    //   title: t('Pay Service'),
    // },
    {
      url: '/admin/request-logs',
      icon: (stroke?: string) => {
        return <IconNotes stroke={stroke} />;
      },
      title: t('Request Logs'),
    },
    {
      url: '/admin/user-config',
      icon: (stroke?: string) => {
        return <IconUserCog stroke={stroke} />;
      },
      title: t('Account Initial Config'),
    },
    {
      url: '/admin/global-configs',
      icon: (stroke?: string) => {
        return <IconSettings stroke={stroke} />;
      },
      title: t('Global Configs'),
    },
    {
      url: '/admin/invitation-code',
      icon: (stroke?: string) => {
        return <IconIdBadge stroke={stroke} />;
      },
      title: t('Invitation Code Management'),
    },
  ];

  useEffect(() => {
    document.title = 'Chats Admin';
  }, []);

  return (
    <div className="h-full w-full flex">
      <div className="min-w-[16rem] h-screen" style={{ borderRightWidth: 1 }}>
        <div className="px-4 py-4 overflow-y-auto">
          <a
            onClick={() => {
              router.push('/');
            }}
            className="flex items-center cursor-pointer gap-2"
          >
            <img
              className="h-8 w-8 rounded-sm"
              alt="Chats Logo"
              src="/icons/logo.png"
            />
            <span className="self-center text-2xl font-medium whitespace-nowrap">
              Chats
            </span>
          </a>
        </div>
        <Nav menus={menus} />
      </div>
      <div className="w-full">
        <div className="h-screen overflow-scroll p-4">{children}</div>
      </div>
    </div>
  );
};

export default AdminLayout;
