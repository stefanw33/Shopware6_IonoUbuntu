<?php declare(strict_types=1);

namespace GuestPriceVisibility\Subscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\ResponseEvent;
use Symfony\Component\HttpKernel\KernelEvents;

class GuestPriceVisibilitySubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [
            KernelEvents::RESPONSE => 'onResponse',
        ];
    }

    public function onResponse(ResponseEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        $request = $event->getRequest();
        $response = $event->getResponse();

        $salesChannelContext = $request->attributes->get('sw-sales-channel-context');
        if (!is_object($salesChannelContext) || !method_exists($salesChannelContext, 'getCustomer')) {
            return;
        }

        if (!str_contains((string) $response->headers->get('Content-Type'), 'text/html')) {
            return;
        }

        if ($salesChannelContext->getCustomer() !== null) {
            return;
        }

        $content = $response->getContent();
        if (!is_string($content) || stripos($content, '</head>') === false) {
            return;
        }

        $style = '<style id="guest-price-visibility">'
            . '.guest-price-hidden,.product-price,.product-detail-price,.product-box-price,'
            .'.cart-item-price,.checkout-aside-summary-value,[itemprop="price"],[itemprop="lowPrice"]'
            . '{visibility:hidden!important;} '
            .'.guest-price-hidden::after,.product-price::after,.product-detail-price::after,.product-box-price::after,'
            .'.cart-item-price::after,.checkout-aside-summary-value::after'
            . '{content:"Preis nach Anmeldung sichtbar";visibility:visible!important;display:inline-block;} '
            .'</style>';

        $response->setContent(str_ireplace('</head>', $style . '</head>', $content));
    }
}
