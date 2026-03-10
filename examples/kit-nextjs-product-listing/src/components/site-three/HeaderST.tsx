import { faShoppingCart } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  Link as ContentSdkLink,
  NextImage as ContentSdkImage,
  LinkField,
  ImageField,
  AppPlaceholder,
} from '@sitecore-content-sdk/nextjs';
import Link from 'next/link';
import { MiniCart } from './non-sitecore/MiniCart';
import { SearchBox } from './non-sitecore/SearchBox';
import { ComponentProps } from 'lib/component-props';
import componentMap from '.sitecore/component-map';
import { MobileMenuWrapper } from './MobileMenuWrapper';

interface Fields {
  Logo: ImageField;
  SupportLink: LinkField;
  SearchLink: LinkField;
  CartLink: LinkField;
}

type HeaderSTProps = ComponentProps & {
  params: { [key: string]: string };
  fields: Fields;
};

const navLinkClass = 'block p-4 font-[family-name:var(--font-accent)] font-medium';

/** Returns true if the link field has a valid href (not a placeholder like # or http://#). */
function hasValidLink(field: LinkField | undefined): boolean {
  const href = field?.value?.href;
  return !!(href && href !== '#' && !href.startsWith('http://#'));
}

export const Default = (props: HeaderSTProps) => {
  const { fields } = props;
  const hasValidSupportLink = hasValidLink(fields?.SupportLink);
  const hasValidSearchLink = hasValidLink(fields?.SearchLink);
  const hasValidCartLink = hasValidLink(fields?.CartLink);

  return (
    <section className={`${props.params?.styles}`} data-class-change>
      <div className="flex justify-between items-start">
        <Link
          href="/"
          className="relative flex justify-center items-center grow-0 shrink-0 w-24 lg:w-32 h-24 lg:h-32 p-4 lg:p-6 bg-primary z-100"
          prefetch={false}
        >
          <ContentSdkImage field={props.fields?.Logo} className="w-full h-full object-contain" />
        </Link>

        <div
          className="relative flex [.partial-editing-mode_&]:flex-col-reverse justify-between items-start gap-10 grow max-w-7xl lg:px-4 bg-background"
          role="navigation"
        >
          <ul className="hidden lg:flex flex-row lg:[.partial-editing-mode_&]:!flex-col text-left bg-background">
            <AppPlaceholder
              name={`header-navigation-${props.params?.DynamicPlaceholderId}`}
              rendering={props.rendering}
              page={props.page}
              componentMap={componentMap}
            />
          </ul>
          <div className="basis-full lg:basis-auto lg:ml-auto">
            <ul className="flex">
              <li className="hidden lg:block">
                {hasValidSupportLink ? (
                  <ContentSdkLink
                    field={fields?.SupportLink}
                    prefetch={false}
                    className={navLinkClass}
                  />
                ) : (
                  <span className={navLinkClass}>{fields?.SupportLink?.value?.text || 'Support'}</span>
                )}
              </li>
              <li className="mr-auto lg:mr-0">
                {props.params.showSearchBox ? (
                  <SearchBox searchLink={fields?.SearchLink} />
                ) : hasValidSearchLink ? (
                  <ContentSdkLink
                    field={fields?.SearchLink}
                    prefetch={false}
                    className={navLinkClass}
                  />
                ) : (
                  <span className={navLinkClass}>
                    {fields?.SearchLink?.value?.text || 'Search'}
                  </span>
                )}
              </li>
              <MobileMenuWrapper>
                <div className="lg:hidden flex flex-col w-full h-full">
                  <div className="flex-1 flex items-center justify-center">
                    <ul className="flex flex-col text-center bg-background">
                      <AppPlaceholder
                        name={`header-navigation-${props.params?.DynamicPlaceholderId}`}
                        rendering={props.rendering}
                        page={props.page}
                        componentMap={componentMap}
                      />
                    </ul>
                  </div>
                  <div className="w-full">
                    <hr className="w-full border-border" />
                    <ul className="text-center">
                      <li>
                        {hasValidSupportLink ? (
                          <ContentSdkLink
                            field={fields?.SupportLink}
                            prefetch={false}
                            className={navLinkClass}
                          />
                        ) : (
                          <span className={navLinkClass}>
                            {fields?.SupportLink?.value?.text || 'Support'}
                          </span>
                        )}
                      </li>
                    </ul>
                  </div>
                </div>
              </MobileMenuWrapper>
              <li>
                {props.params.showMiniCart ? (
                  <MiniCart cartLink={fields?.CartLink} />
                ) : hasValidCartLink ? (
                  <ContentSdkLink
                    field={fields?.CartLink}
                    prefetch={false}
                    className="block p-4"
                  >
                    <FontAwesomeIcon icon={faShoppingCart} width={24} height={24} />
                  </ContentSdkLink>
                ) : (
                  <span className="block p-4" aria-label="Shopping cart">
                    <FontAwesomeIcon icon={faShoppingCart} width={24} height={24} />
                  </span>
                )}
              </li>
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
};
